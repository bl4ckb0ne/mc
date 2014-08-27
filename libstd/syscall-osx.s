.globl _std$syscall
_std$syscall:
	pushq %rbp 
	pushq %rdi 
	pushq %rsi 
	pushq %rdx 
	pushq %r10 
	pushq %r8
	pushq %r9
	pushq %rcx 
	pushq %r11 
	/*
	hack: We load 6 args regardless of
	how many we actually have. This may
	load junk values, but if the syscall
	doesn't use them, it's going to be
	harmless.
	 */
	movq 80 (%rsp),%rax
	movq 88 (%rsp),%rdi
	movq 96 (%rsp),%rsi
	movq 104(%rsp),%rdx
	movq 112(%rsp),%r10
	movq 120(%rsp),%r8
	movq 128(%rsp),%r9

	syscall
	jae .success
	negq %rax

.success:
	popq %r11
	popq %rcx
	popq %r9
	popq %r8
	popq %r10
	popq %rdx
	popq %rsi
	popq %rdi
	popq %rbp
	ret

/*
 * OSX is strange about fork, and needs an assembly wrapper.
 * The fork() syscall, when called directly, returns the pid in both
 * processes, which means that both parent and child think they're
 * the parent.
 *
 * checking this involves peeking in %edx, so we need to do this in asm.
 */
.globl _std$__osx_fork
_std$__osx_fork:
	pushq %rbp
	pushq %rdi 
	pushq %rsi 
	pushq %rdx 
	pushq %r10 
	pushq %r8
	pushq %r9
	pushq %rcx 
	pushq %r11 

	movq $0x2000002,%rax
	syscall

	jae .forksuccess
	negq %rax

.forksuccess:
	testl %edx,%edx
	jz .isparent
	xorq %rax,%rax
.isparent:

	popq %r11 
	popq %rcx 
	popq %r9
	popq %r8
	popq %r10 
	popq %rdx 
	popq %rsi 
	popq %rdi 
	popq %rbp
	ret

/*
 * OSX is strange about pipe, and needs an assembly wrapper.
 * The pipe() syscall returns the pipes created in eax:edx, and
 * needs to copy them to the destination locations manually.
 */
.globl _std$__osx_pipe
_std$__osx_pipe:
	pushq %rbp
	pushq %rdi 
	pushq %rsi 
	pushq %rdx 
	pushq %r10 
	pushq %r8
	pushq %r9
	pushq %rcx 
	pushq %r11 

	movq $0x200002a,%rax
	syscall

	jae .pipesuccess
	negq %rax

.pipesuccess:
	movq 80(%rsp),%rdi
	movl %eax,(%rdi)
	movl %edx,4(%rdi)
	xorq %rax,%rax

	popq %r11 
	popq %rcx 
	popq %r9
	popq %r8
	popq %r10 
	popq %rdx 
	popq %rsi 
	popq %rdi 
	popq %rbp
	ret

.globl _std$__osx_gettimeofday
_std$__osx_gettimeofday:
	pushq %rbp
	pushq %rdi 
	pushq %rsi 
	pushq %rdx 
	pushq %r10 
	pushq %r8
	pushq %r9
	pushq %rcx 
	pushq %r11 

	movq $0x2000074,%rax
	syscall

	jae .gettimeofdaysuccess
	negq %rax

.gettimeofdaysuccess:
	movq 80(%rsp),%rdi
	movq %rax, (%rdi)
	movl %edx,8(%rdi)
	xorq %rax,%rax

	popq %r11 
	popq %rcx 
	popq %r9
	popq %r8
	popq %r10 
	popq %rdx 
	popq %rsi 
	popq %rdi 
	popq %rbp
	ret

