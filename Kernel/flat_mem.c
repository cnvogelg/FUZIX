/*
 *	Flat memory manager taken from the original MAPUX work by
 *	Martin Young. "Do what you want with it" licence.
 *
 *	This version has been tidied up and ANSIfied
 *
 *	The code needs some work, particularly on the efficiency side. On the
 *	plus side however it does allow us to do brk() properly, it handles
 *	fork() and it does allow memory compaction and rearrangement as well
 *	as expanding to support multi-segment binaries and relocations not
 *	just binfmt_flat (eg Amiga style).
 *
 *	TODO:
 *		Further type cleaning
 *		Allow for multiple memory pools. This isn't totally trivial
 *			because we cannot merge across pools.
 *		Integrate swapping
 *		See if it's actually worth the overhead. In particular see
 *			what occurs when combines with swapping. Arguably with
 *			hard disc we we want to favour swapping over colaescing.
 *		Support read-only blocks (duplicate by ref count) for pure
 *		code segments and for re-entrant executables (and shared libs)
 *		Optimizations (list splitting etc)
 *		Pinning. This is actually quite hairy because we need to know
 *		that the address we are pinning has *no* users in any list.
 *		That will require better data structures for va management.
 */

#include "kernel.h"
#include "flat_mem.h"

/* These are essentially inline functions and should help speed things
   up a bit */

#define wholeblks(a)	(((a) + BLKSIZE - 1) / BLKSIZE)
#define mapped(a)	((a)->vaddr == blktoadd(a))
#define partof(l,b)	((b)->home == l)

static struct memblk *memmap;
static unsigned long freemem;

static uint8_t *blktoadd(struct memblk *m)
{
	return membase + (m - memmap) * BLKSIZE;
}

static struct memblk *addtoblk(uint 8_t *p)
{
	return memmap + (p - membase) / BLKSIZE;
}

/*
 *  This needs to be called before any allocations occur
 *  FIXME: put the map at the *top* of space and we can then align the
 *  data blocks if the platform needs big alignments.
 */
void vmmu_init(void)
{
	struct memblk *blk, *last;
	uint8_t	*addr;
	/* How many blocks + headers fit into the space ? */
	ssize_t mapsize = (memtop - membase) / (BLKSIZE + sizeof(struct memblk));

	/* The map array */
	memmap = membase;
	/* The memory blocks themselves */
	membase += mapsize * sizeof(struct memblk);

	/* Consume the bottom of memory creating a block map */
	last = &freelist;
	last->prev = NULL;
	for(addr = membase; addr < memtop; addr += BLKSIZE) {
		blk = last->next = addtoblk(addr);
		blk->vaddr = addr;
		blk->prev = last;
		blk->home = &freelist;
		last = blk;
	}
	last->next = NULL;
	freemem = mapsize * BLKSIZE;
	/* Trim off any partial block at the top */
	memtop = membase + freemem;
}

/*
 * Returns the amount of overrun (in blocks) of a memory area blks long
 * from the block here.
 */
static int overrun(struct memblk *here, int blks)
{
	int res = 0;
	while(here && ++res < blks)
		here = here->next;
	return blks - res;
}

/*
 * Calculates the length of a list. Might be worth having this
 * to hand in the header but it's not in a hot path.
 */
static int listlen(struct memblk *list)
{
	int	count = 0;
	while (list) {
		count++;
		list = list->next;
	}
	return count;
}

/*
 * Moves num blocks from the slist to the dlist starting with block first
 */
static void moveblks(struct memblk *slist, struct memblk *dlist,
				struct memblk *first, unsigned int num)
{
	struct memblk *nlink, *after, *ofirst;
	unsigned int i;

	if (num == 0)
		return;

	/* A useful number: the address of the block following the segment */
	/* Also updates the blocks owner (optimisation only) and eliminates
	   reserved gaps */
	i = num;
	after = first;
	while (after && i--) {
		after->home = dlist;
		after->gap = 0;
		after = after->next;
		if (dlist == &freelist)
			freemem += BLKSIZE;
		if (slist == &freelist)
			freemem -= BLKSIZE;
	}

	/* This will be overwritten unless the operation is a simple join */
	if (after)
		after->prev->next = 0;

	/* This removes the segment from the orginal list */
	first->prev->next = after;
	if (after)
		after->prev = first->prev;

	/* The additional list segment and the destination list may be
	   interleaved */
	while (1) {
		if (dlist->next == NULL) {
			dlist->next = first;
			first->prev = dlist;
			break;
		}
		if (dlist->next < first)
			dlist = dlist->next;
		else if (dlist->next > first) {
			nlink = dlist->next;
			dlist->next = first;
			first->prev = dlist;
			while (first->next && (first->next<nlink) && --num)
				first = first->next;
			num--;
			if (num == 0) {
				first->next = nlink;
				nlink->prev = first;
				break;
			}
			ofirst = first->next;
			first->next = nlink;
			nlink->prev = first;
			first = ofirst;
			dlist = nlink;
		}
		else if (dlist->next == first)
			panic( "vmmu collision\n");
	}
}


/*
 * Try to allocate a brand new piece of memory.
 * It is added to the memory list of a particular process identified by the
 * parameter.
 *
 * addr is the preferred physical address if any
 * resv is how much virtual address space we want to reserve after this
 * block in order to allow for brk().
 * safe is set if we know the va proposed is free in the process map - eg for
 * a fork or a swapin.
 */
void *vmmu_alloc(struct memblk *list, size_t size, void *addr, size_t resv, int safe)
{
	unsigned int nblks = wholeblks(size);
	struct memblk *this, *freeb, *start, *bstart;
	int	num, tot, bestlen, back, i;
	uint8_t	*base, *proposed, *proposed_end;
	int	lastmove;

	if (nblks == 0)
		panic("zalloc");

	/* If a specific address has been requested try to return that piece
	   of physical memory. This will fail on a fork but hopefully will
	   sometimes work out on a swap in or brk() */
	if (addr && partof(&freelist,addtoblk(addr)) && 
	    (overrun(&freelist,nblks) == 0)) {
		bstart = addtoblk(addr);
		goto mapper;
	}

	/* The second thing is to find a contiguous free area we can use */
	this = bstart = start = freelist.next;
	bestlen = 1;

	num = 1;
	tot = 0;

	/* Walk the free list looking for enough blocks to be interesting.
	   Again this is inefficient and we ought to do list splitting not
	   walk the entire lot, but that can be fixed later FIXME */
	while(this) {
		tot++;
		if (this->next == this + 1) {
			if (++num >= nblks) {
				bstart = start;
				break;
			}
		} else {
			if (num > bestlen ) {
				bestlen = num;
				bstart = start;
			}
			num = 1;
			start = this->next;
		}
		this = this->next;
	}

	/* Out of memory */
	if (tot + 1 < nblks)
		return NULL;

	/* Proposed virtual address - coincides with first physical. */
	if (addr == NULL)
		proposed = blktoadd(bstart);
	else
		proposed = addr;

	/* Found a suitable contiguous lump: FIXME still need to check va
	   if we are not the live context, and safe is not true. In the
	   case we are the live context then the va of the new block is
	   free by definition since we are mapped */
	if (num >= nblks)
		goto mapper;

#ifndef CONFIG_SWAP	
	/*
	 * Space, but it's dotted about.
	 *
	 * FIXME: To merge a kernel malloc into this we need to add
	 * a "pinned" flag and some intelligence about pinning stuff
	 * at one end.
	 */

	/* Move back if longest area is too near the end */
	/* Note we move far enough to fit in the reserved bit too */
	back = overrun(bstart, nblks + resv);
	while (back && bstart->prev)
		bstart = bstart->prev;
	/*
	 * The address we pick for the block must also not clash with the
	 * virtual address of an existing chunk of memory we are using in
	 * this process. This code isn't exactly efficient but we typically
	 * only have a few blocks on our list. We can fix that later by
	 * some simple sort ordering of the list by vaddr. FIXME.
	 */

	proposed_end = proposed + BLKSIZE * nblks;

	/* This stops infinite up/down/up/down loops */
	lastmove = 0;	
	while(1) {
		int	hit = 0;
		uint8_t	*lowhit = memtop,
			*tophit = membase,
			*gapend;
		this = list->next;
		while (this)
		{
			/* Check the block itself */
			if (this->vaddr > proposed &&
			    this->vaddr < proposed_end) {
				hit = 1;
				if (this->vaddr < lowhit)
					lowhit = this->vaddr;
				if (this->vaddr > tophit)
					tophit = this->vaddr;
			}
			/* Also check a possible reserved area attached */
			if (this->gap) {
				gapend = this->vaddr + (this->gap * BLKSIZE);
				if (gapend > proposed &&
					gapend < proposed_end) {
					hit = 1;
					if (gapend < lowhit)
						/* Is this line right? */
						lowhit = this->vaddr;
					if (gapend > tophit)
						tophit = this->vaddr;
				}
			}
			this = this->next;
		}
		/* No clash, continue */
		if (hit == 0)
			break;
		/* There is a clash, so try to fix it by moving the new one
		   down */
		if ((ssize_t)lowhit - nblks * BLKSIZE >= membase
						&& lastmove != 1) {
			lastmove = -1;
			proposed = lowhit - nblks * BLKSIZE;
			continue;
		}
		/* Alternatively move the new virtual address up */
		if ((ssize_t)tophit + nblks * BLKSIZE < memtop
							&& lastmove != -1) {
			lastmove = 1;
			proposed = tophit + nblks * BLKSIZE;
			continue;
		}
		/* If we get here then we couldn't resolve the conflict */
		kputs("alloc: vaddr conflict");
		return NULL;	/* Whole call fails */
	}
#else
	/* If we have swap then drive the memory to swap rather than cause
	   fragmentation and reallocation problems */
	return NULL;
#endif	
	/* Move the blocks from the freelist and create an address mapping */
mapper:
	moveblks(&freelist, list, bstart, nblks);
	base = addr ? addr : proposed;
	for (this = bstart, i = 0; i < nblks; i++, base += BLKSIZE) {
		fast_zero_block(blktoadd(this));
		this->vaddr = base;
		this = this->next;
	}
	this->prev->gap = resv;
	fast_op_complete();
	return bstart->vaddr;
}


/*
 *  Moves blocks about to make the given mapping physically valid. We use this
 *  when we context switch in order to force our process into the right
 *  locations while dealing with the joys of things like fork().
 */
void vmmu_setcontext(struct memblk *list)
{
	struct memblk *here, *oblk;

	here = list->next;

	while(here) {
		struct memblk *nxt = here->next;
		if (mapped(here) == 0) {
			/* Fast swap provided by platform for aligned blocks */
			fast_swap_block(blktoadd(here), here->vaddr);
			oblk = addtoblk(here->vaddr);
			moveblks(list, oblk->home, here, 1);
			moveblks(oblk->home, list, oblk, 1);
		}
		here = nxt;
	}
	fast_op_complete();
}

/*
 *  Frees a process memory blocks
 */
void vmmu_free(struct memblk *list)
{
	if( list->next != NULL) {
		moveblks(list, &freelist, list->next, listlen(list->next));
		list->next = 0;
	}
}

/*
 *  Creates a copy of a given list when forking
 *
 *  This can easily fail because of lack of memory
 *  Note list is a pointer to the first block in the source, but dest
 *  is a pointer to a root block
 */
int vmmu_dup(struct memblk *list, struct memblk *dest)
{
	dest->next = 0;
	if (vmmu_alloc(dest, listlen(list) * BLKSIZE, list->vaddr)) {
		struct memblk *new  = dest->next, *here = list;
		while(here) {
			new->vaddr = here->vaddr;
			fast_copy_block(blktoadd(here), blktoadd(new));
			new = new->next;
			here = here->next;
		}
		fast_op_complete();
		return 0;
	}
	return -1;
}


struct mmu_context {
	struct memblk mmu;
	uint8_t *base;
};

static uint16_t last_context;
static struct mmu_context *last_mmu;
static struct mmu_context mmu_context[PTABSIZE]

/* For the moment. If we add separate va info then we can use that if not
   we use the map table */
usize_t valaddr(const char *pp, usize_t l)
{
	struct memblk *m = addtoblk(pp);
	usize_t n = 0;
	/* Number of bytes we have in the first page */
	usize_t slack = BLKSIZE - ((usize_t)pp & (BLKSIZE - 1));

	if (pp < membase || pp + l >= memtop || pp + l < pp)
		return 0;
	/* Note the usual path through here avoids the computation and
	   most calls do the loop only once */
	while(n < l) {
		if (m->home != &last_mmu.mmu)
			return (n - 1) * BLKSIZE + slack;
		n++;
		m++;
	}
	return l;
}

/* Uget/Uput 32bit */

uint32_t ugetl(void *uaddr, int *err)
{
	if (!valaddr(uaddr, 4)) {
		if (err)
			*err = -1;
		return -1;
	}
	if (err)
		*err = 0;
#ifdef MISALIGNED
	if (MISALIGNED(uaddr, 4)) {
		*err = -1;
		ssig(udata.u_proc, SIGBUS);
		return -1;
	}
#endif
	return *(uint32_t *)uaddr;

}

int uputl(uint32_t val, void *uaddr)
{
	if (!valaddr(uaddr, 4))
		return -1;
#ifdef MISALIGNED
	if (MISALIGNED(uaddr, 4)) {
		ssig(udata.u_proc, SIGBUS);
		return -1;
	}
#endif
	return *(uint32_t *)uaddr;
}

/* Fork and similar */
int pagemap_alloc(ptptr p)
{
	unsigned int nproc = p - ptab;
	struct mmu_context *m = &mmu_context[nproc];
	p->p_page = nproc;	/* Just a number for debug */

	/* Special case to construct the init bootstrap */
	if (p->p_pid == 1) {
		platform_mmu_setup(m);
		return 0;
	}
	if (vmm_dup(&mmu_context[udata.p_page].mmu->head, &m.mmu))
		return ENOMEM;
	return 0;
}

/* pagemap_switch */
void pagemap_switch(ptptr p)
{
	if (udata.u_page == last_context)
		return;
	last_context = udata.u_page;
	last_mmu = &mmu_context[udata.u_page];
	vmmu_setcontext(&last_context->mmu);
}

void pagemap_free(ptptr p)
{
	vmmu_free(&mmu_context[udata.u_page].mmu);
	last_context = -1;
}

int pagemap_realloc(usize_t size)
{
	struct mmu_context *mmu = mmu_context + udata.u_page;
	pagemap_free(udata.u_ptab);
	mmu->base = mmu_alloc(&mmu->mmu, size, NULL, 0, 1);
	if (mmu->base == NULL)
		return ENOMEM;
	return 0;
}

void *pagemap_base(void)
{
	return mmu_context[udata.u_page].base;
}

usize_t pagemap_mem_used(void)
{
	return freemem >> 10;
}

int pagemap_fork(ptptr p)
{
	struct mmu_context *parent = mmu_context + p->page;
	struct mmu_context *child = mmu_context + udata.u_page;
	return vmmu_dup(parent->mmu.next, &child.mmu);
}

#define size (uint32_t)udata.u_argn
#define flags (uint32_t)udata.u_argn1

static arg_t memalloc(void)
{
	void *addr;
	if (flags) {
		udata.u_error = EINVAL;
		return -1;
	}
	addr = mmu_alloc(&mmu->mmu, size, NULL, 0, 0);
	if (addr == NULL) {
		udata.u_error = ENOMEM;
		return -1;
	}
	return (arg_t)addr;
}

#undef size
#undef flags

#define base (void *)udata.u_argn

static arg_t memfree(void)
{
	/* Not yet supported - needs reworking of vmmu_free to support
	   freeing page ranges nicely */
	udata.u_error = ENOSYS;
	return -1;
}

