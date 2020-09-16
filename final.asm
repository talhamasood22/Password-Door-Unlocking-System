org 0000H
	jmp main
org 0003H
	call delay_25ms
	clr ex0
	jmp ex0_isr
org 0013H
	call delay_25ms
	clr ex1
	jmp ex1_isr
	
org 0030H
	main:  
						;start program
	mov p0,#0
	mov p1,#0
	mov p2,#0
	mov p3,#0
	mov sp,#1fH			;for password
	setb ea
	mov a,#0fH
	call command_write
	mov a,#38H
	call command_write
	mov a,#80H
	call command_write
	mov dptr,#welcome
	call display
	call delay_1s
	mov a,#80H
	call command_write
	call clearline
	mov a,#80H
	call command_write
	mov dptr,#enterpass
	call display
	call peoplecount		
	mov 10H,#3			;for no of attempts
	                    ;keypad input
mov p1,#0
mov p2,#0ffh
rows equ  4
cols equ  3
digits equ 4				;no of password digits
mov r5,#digits	

mov a,#0h
mov r1,#0h
rot_again: 
setb c
inc r1
rlc	a
cjne r1,#cols,rot_again
mov 35H,a
jmp keypad_scan

startforex0:
call returntoex0

mov sp,#1fH
mov a,30H
cjne a,#0,enableexit
clr ex1
jmp keypad_scan
enableexit:
setb p3.3
setb ex1

keypad_scan:
mov r0,35H
mov p1,#0
mov p2,#0ffh
mov r1,#0feh
mov r2,#0
mov r3,#0

next_row:
mov p1,r1 
mov a,p2
anl a,r0
cjne a,0h,key_pressed
mov a,r1
rl a
mov r1,a
inc r2
cjne r2,#rows,next_row
jmp keypad_scan

key_pressed:
call delay_25ms
again1:
rrc a
jnc findkey
inc r3
jmp again1

findkey:
mov a,#cols
mov b,r2
mul ab
add a,r3
mov dptr,#key
movc a,@a+dptr
mov r4,a         ;keypad input in r4

release_key:
mov a,p2
anl a,r0
cjne a,0h,release_key
call delay_25ms


input_taken:
push 4H
djnz r5,keypad_scan
mov r5,#digits

compare:
mov dptr,#password
mov r0,#0
mov r1,#20H
next_digit:
mov a,r0
movc a,@a+dptr
mov r2,a
mov a,@r1
cjne a,02H,wrongpass
inc r0
inc r1
djnz r5,next_digit

correctpass:
	mov r5,#digits
	mov sp,#1fH
	mov 10H,#3
	mov a,#0C0H
	call clearline
	mov a,#0C0H
	call command_write
	mov dptr,#correctline
	call display
	mov a,#90H
	call command_write		;cursor--->3rd line
	mov dptr,#timeleft
	call display
	mov 15H,#5
	setb p3.2
	setb ex0
	setb it0
	call dooropen					;door open
	
	
	
	countdown:
	mov a,15H
	add a,#30H
	call data_write
	call delay_1s
	mov a,#10H
	call command_write		;cursor-->left
	djnz 15H,countdown
	call doorclose						;door close
	mov a,#90H
	call clearline
	mov a,#0c0H
	call clearline
	clr ex0
	jmp keypad_scan
	

wrongpass:
	mov r5,#digits
	mov sp,#1fH
	mov a,#0c0H
	call clearline
	mov a,#0C0H
	call command_write
	mov dptr,#wrongline
	call display
	call delay_1s
	mov a,#0c0H
	djnz 10H,startagain
	jmp alarm
	startagain:
	jmp keypad_scan
	alarm:
	cpl p3.7
	call delay_1s
	jb p3.1,securityarrived
	jmp alarm
	securityarrived:
	clr p3.7
	mov 10H,#3
	mov a,#0c0H
	call clearline
	jmp keypad_scan
	

;ISRs


ex0_isr:
	call doorclose		;door close
	mov a,#0c0H
	call clearline
	mov a,#90H
	call clearline
	inc 30H
	call peoplecount
	setb p3.3
	setb ex1
	setb it1
	mov a,30H
	jmp startforex0
	returntoex0:
	cjne a,#10,return_isr
	jmp roomfull
	roomfull:
	mov a,#80H
	call clearline
	call stayhere
	jmp $
	stayhere:
	RETI
	return_isr:
			RETI
ex1_isr:
	clr ex0
	mov a,#80H
	call command_write
	mov dptr,#enterpass
	call display
	mov a,#0c0H
	call clearline
	mov a,#90H
	call clearline
	dec 30H
	call peoplecount
	mov a,#0c0H
	call command_write
	mov dptr,#wait
	call display
	call dooropen		;door open
	call delay_1s
	call delay_1s
	call delay_1s
	call doorclose		;door close
	mov a,#0c0H
	call clearline
	setb ex1
	jmp startforex0

;subroutines


command_write:
clr p3.5
clr p3.6
mov p0,a
setb p3.4
clr p3.4
call delay_25ms
ret

data_write:
setb p3.5
clr p3.6
mov p0,a
setb p3.4
clr p3.4
call delay_25ms
ret

peoplecount:
	mov a,#0D0H   		;for last line
	call clearline
	mov a,#0D0H
	call command_write
	mov dptr,#peeps
	call display
	mov a,30H
	cjne a,#10,singledigit
	mov a,#31H
	call data_write
	mov a,#30H
	call data_write
	ret
	singledigit:
	add a,#30H
	call data_write
ret

clearline:
	call command_write
	mov r0,#16
	mov a,#20H
	moveon2:
	call data_write
	djnz r0,moveon2
ret

display:
	mov r0,#0
	moveon:
	mov a,r0
	movc a,@a+dptr
	jz exitdisplay
	call data_write
	inc r0
	jmp moveon
	exitdisplay:
ret

doorclose:
mov r7,#50
closeloop2:
setb p3.0
call delay_500us
call delay_500us
clr p3.0
mov r6,#38
closeloop:
call delay_500us
djnz r6,closeloop
djnz r7,closeloop2
ret

dooropen:
mov r7,#50
openloop2:
setb p3.0
call delay_500us
call delay_500us
call delay_500us
clr p3.0
mov r6,#37
openloop:
call delay_500us
djnz r6,openloop
djnz r7,openloop2
ret

delay_25ms:
MOV R6,#45
 loop1:
 MOV R7,#255
 DJNZ R7,$
 DJNZ R6,loop1
ret

delay_500us:
mov tmod,#00010000B
mov tl1,#33H
mov th1,#0FEH
clr tf1
setb tr1
jnb tf1,$
clr tr1
ret

delay_1s:
mov r6,#20
mov tmod,#00000001
loop2:
mov tl0,#00H
mov th0,#4CH
clr tf0
setb tr0
jnb tf0,$
clr tr0
djnz r6,loop2
ret


;lists

welcome: db "Welcome...!",0
enterpass: db "4 digit Pass?",0
peeps: db "People Inside:",0
key: db '1','2','3','4','5','6','7','8','9','*','0','#',0 
password: db "1234"
wrongline: db "Incorrect pass",0
correctline: db "Correct pass",0
timeleft: db "Time to Enter: ",0
wait: db "Please wait...",0	

end