#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#


; add your code here

jmp     st1
db     509 dup(0)



TABLE DB    77h,7Bh,7Dh,7Eh,0EDh,0BBh,0BDh,0BEh,0D7h,0DBh,0DDh,0DEh,0E7h,0EBh					



db     479 dup(0)
floor     db 0
fine db 0
cs1 db 0
cs2 db 0
ground_in db 0
ground_up db 0
first_up db 0
first_down db 0
first_in db 0
second_down db 0
second_in db 0
second_up db 0
third_down db 0
third_in db 0
door_close db 0
direction db 0
slow db 0
press db 0
press_out db 0

cnt0 equ 08h
cnt1 equ 0ah
cnt2 equ 0ch
cr_8253 equ 0eh
		
;main program

st1:      cli
; intialize ds, es,ss to start of RAM
mov       ax,0200h
mov       ds,ax
mov       es,ax
mov       ss,ax
mov       sp,0FFFEH

;keypad 8255 initializing

		mov al,10000010b
		out 06h,al
		
		mov al,10000000b
		out 16h,al
		
		
		
;initializing 8253

	;loading value to get 0% duty cycle at the start
	
	;initializing counter0 with 10
	mov	al,00010110b  ; square wave generator with mode 3.
	out	cr_8253,al 
	mov	al,0Ah ; LSB
	out	cnt0,al 
	
	
	mov	al,01010010b
	out	cr_8253,al
	mov	al,0Ah
	out	cnt1,al

		;initialise all flag variables with 00h
		mov al,00h
		mov fine,al
		mov cs1,al
		mov cs2,al
		mov ground_in,al
		mov ground_up,al
		mov first_up,al
		mov first_down,al
		mov first_in,al
		mov second_down,al
		mov second_in,al
		mov second_up,al
		mov third_down,al
		mov third_in,al
		mov door_close,al
		mov slow,al
		mov press,al
		mov press_out,al
		mov al,00h
		mov floor,00h
		
;lift starts with the door open
		call open_lift

		mov al,00h							;looping back here when floor = 00h or ground
lift_1:	call button_press					;button_press function returns or of all buttons inside and outside the lift
		mov al,press						;press returns the value of or
		cmp al,01h							;check if any button is already pressed
		jz lift_2								;if pressed, start moving in the upward direction
		call keybrd
		call key_press  					;check for button press
		cmp al,00h
		jz lift_1
		call button_outside					;check if any of the buttons outside the lift(up and down) are pressed. This is used for door open/close
		mov al,press_out
		cmp al,00h
		jnz lift_2
		mov al,00h
key_1:		call keybrd							;if any button is pressed inside the lift, wait for door_close button to move up
		call key_press
		cmp al,00h
		jz key_1
		mov al,door_close					;check if door close is set
		cmp al,01h
		jnz key_1
		mov al,00h
		mov door_close,al					;reset door_close flag
lift_2:	call close_lift
		mov al,01h
		mov direction,al					;set direction to up (01h)
		call speed_up						;set lift in motion
		
		mov al,00h
lift_3:	call keybrd							;check for cs1 using polling
		call key_press
		cmp al,00h
		jz lift_3
		mov al,cs1							;check if cs1 flag is set
		cmp al,01h
		jnz lift_3
		call coarse_1							;call coarse_1 function
		
		mov al,00h
lift_4:	call keybrd							;check for cs2 using polling
		call key_press
		cmp al,00h
		jz lift_4
		mov al,cs2							;check if cs2 flag is set
		cmp al,01h
		jnz lift_4
		call coarse_2							;call coarse_2 function
		
		mov al,00h
lift_5:	call keybrd							;check for fine using polling
		call key_press
		cmp al,00h
		jz lift_5
		mov al,fine							;check if fine flag is set
		cmp al,01h
		jnz lift_5
		call coarse_fine							;call coarse_fine function
		
		mov al,floor						;after return from fine function, if floor is ground, then loop to beginning
		cmp al,00000000b
		jz lift_1
		mov al,direction					;depending on direction, check cs1 (direction = up) or cs2 (direction = down)
		cmp al,01h
		jnz lift_6
		jmp lift_3
lift_6:			

		mov al,00h
lift_7:	call keybrd							;check for cs2 using polling
		call key_press
		cmp al,00h
		jz lift_7
		mov al,cs2							;check if cs2 flag is set
		cmp al,01h
		jnz lift_7
		call coarse_2							;call coarse_2 function

		mov al,00h
lift_8:	call keybrd							;check for cs1 using polling
		call key_press
		cmp al,00h
		jz lift_8
		mov al,cs1							;check if cs1 flag is set
		cmp al,01h
		jnz lift_4
		call coarse_1							;call coarse_1 function
		
		jmp lift_5

;taking inputs using keyboard matrix
keybrd proc near


PUSHF
PUSH BX
PUSH CX
PUSH DX
;send 0's to all rows
mov al,00
mov dx,00h
out dx,al

;read columns
mov dx,02h   ;load input port address


wait_open :
in al,dx
and al,0fh
cmp al,0fh
jne wait_open

;read colunms to see if key is pressed
wait_press :
in al,dx
and al,0fh
cmp al,0fh
je wait_press




delay123: loop delay123

;read columns to see if key still pressed
in al,dx
and al,0fh
cmp al,0fh
je wait_press

;find key

mov al,0feh
mov cl,al

next_row:

mov dx,00h
out dx,al
mov dx,02h
in al,dx
and al,0fh
cmp al,0fh
jne encode
rol cl,01
mov al,cl
jmp next_row


encode:
mov bx,000fh
in al,dx


try_next :
cmp al,table[bx]
je done
dec bx
jns try_next
mov ah,01h
jmp exit


done:
mov al,bl
mov ah,00h



exit:

POP DX
POP CX
POP BX
POPF
ret

keybrd endp

;sub-routine to set the button pressed by the user
key_press proc near

PUSHF
PUSH BX
PUSH CX
PUSH DX



y1:   cmp al, 77h
jnz y2
mov al, 0ah
mov al,1
mov cs1,al
jmp y0

y2:   cmp al, 7Bh
jnz y3
mov al, 00h
mov al,1
mov fine,al
jmp y0

y3:   cmp al, 7Dh
jnz y4
mov al, 0bh
mov al,1
mov cs2,al
jmp y0

y4:   cmp al, 7Eh
jnz y5
mov al, 0ch
mov al,1
mov ground_up,al
jmp y0

y5:   cmp al, 0EDh
jnz y6
mov al, 01h
mov al,1
mov ground_in,al
jmp y0

y6:   cmp al, 0BBh
jnz y7
mov al, 02h
mov al,1
mov first_up,al
jmp y0

y7:   cmp al, 0BDh
jnz y8
mov al, 03h
mov al,1
mov first_in,al
jmp y0

y8:   cmp al, 0BEh
jnz y9
mov al, 0dh
mov al,01h
mov first_down,al
jmp y0

y9:   cmp al, 0D7h
jnz yA
mov al, 04h
mov al,01h
mov second_up,al
jmp y0

yA:   cmp al, 0DBh
jnz yB
mov al, 05h
mov al,01h
mov second_in,al
jmp y0

yB:   cmp al, 0DDh
jnz yC
mov al,1
mov second_down,al
jmp y0

yC:   cmp al, 0DEh
jnz yD
mov al, 0eh
mov al,1
mov third_in,al
jmp y0

yD:   cmp al, 0E7h
jnz yE
mov al, 07h
mov al,01h
mov third_down,al
jmp y0

yE:   cmp al, 0EBh
jnz y0
mov al, 08h
mov al,01h
mov door_close,al
jmp y0



y0:
nop

POP DX
POP CX
POP BX
POPF
ret
key_press endp



;coarse sensor 2
coarse_2	proc	near
		mov al,00h
		mov cs2,al				;reset coarse sensor 2
		mov al,direction		
		cmp al,10h				;if(direction == down)
		jnz x1
		dec floor				;decrement floor
		mov al,floor
		or al,00100000b
		out 04h,al				;display floor
		jmp exit_cs2
x1:		mov al,floor			
		cmp al,01h				;if(floor == 1)
		jnz x2
		mov al,first_up
		mov dl,first_in
		or al,dl 				;if(first_in || first_up)
		jz x3
		mov al,01h
		mov slow,al				;set slow flag
		call slow_down			;call function to slow lift
		jmp exit_cs2
x3:	    mov al,second_in		
		mov bl,second_up
		or al,bl				
		mov bl,second_down
		or al,bl
		mov bl,third_in
		or al,bl
		mov bl,third_down
		or al,bl 				;if(!(second_in || second_up || third_in || third_down || second_down))
		jnz x2
		mov al,first_down
		cmp al,01h				;if(first_down)
		jnz x2
		mov al,01h
		mov slow,al				;set slow flag
		call slow_down			;call function to slow lift if it has to stop in that floor 
		jmp exit_cs2

x2:		mov al,floor			
		cmp al,00000010b		;check if floor == 2		
		jnz x4
		mov al,second_up
		mov dl,second_in
		or al,dl 				;if(second_in || second_up)
		jz x5
		mov al,01h
		mov slow,al				;set slow flag
		call slow_down			;call function to slow lift if it has to stop in that floor
		jmp exit_cs2

x5:	    mov al,third_in
		mov bl,third_down
		or al,bl 				;if(!(third_in || third_down))
		jnz x4
		mov al,01h
		mov slow,al				;set slow flag
		call slow_down			;call function to slow lift if it has to stop in that floor
		jmp exit_cs2

x4:		mov al,floor			
		cmp al,00000011b		;check if floor == 3
		jnz exit_cs2
		mov al,01h
		mov slow,al				;set slow flag
		call slow_down			;call function to slow lift if it has to stop in that floor
exit_cs2:
		ret
coarse_2	endp

coarse_fine	proc	near
		mov al,00h
		mov fine,al 			;reset fine flag
		mov al,floor
		cmp al,00000000b 		;if(floor==00h)
		jnz x6
		call stop_lift			;if lift is moving to ground floor, stop lift
		mov al,ground_in
		mov bl,ground_up
		or al,bl 				;if(ground_up || ground_in)
		jz x7
		call open_lift			;if ground_in or ground_up is pressed, then open lift
		mov al,01h
		mov direction,al		;set direction to up
x7:		mov al,00h 				
		mov ground_in,al 		;reset ground_in
		mov ground_up,al 		;reset ground_up
		jmp exit_f

x6:		mov al,floor			
		cmp al,00000001b		;if(floor == 1)
		jnz x10
		mov al,slow
		cmp al,01h				;check if slow flag is set
		jnz x81
		call stop_lift			;if slow is set, then stop and open lift
		call open_lift
		mov al,00h
		mov door_close,al
kel1:	call keybrd				;check for floor input from user
		call key_press
		cmp al,00h
		jz kel1
		mov al,00h 				
		mov first_up,al 		;reset first_up
		mov al,00h 				
		mov first_down,al 		;reset first_up
		call button_outside		;check if any of the buttons outside the lift are pressed. if pressed, close lift and move
		mov al,press_out
		cmp al,01h
		jz ke1
		mov al,door_close		;check if door close is pressed
		cmp al,01h
		jnz kel1
ke1:	mov al,00h
		mov door_close,al		;reset door close and close lift
		call close_lift
		mov al,00h
		mov slow,al				;reset slow bit

x81:	mov al,00h 				
		mov first_in,al 		;reset first_in
		mov al,direction		;check direction is up
		cmp al,01h
		jnz x8
		mov al,00h 				
		mov first_up,al 		;reset first_up
		mov al,second_down
		mov bl,second_in
		or al,bl
		mov bl,second_up
		or al,bl
		mov bl,third_down
		or al,bl
		mov bl,third_in
		or al,bl				;if(second_down || second_in || second_up || third_down || third_in) checking if any of the buttons in the floors above are pressed
		jnz exhalf
		mov al,10h
		mov direction,al		;if not, then set direction to down
exhalf:
		call speed_up
		jmp exit_f
x8:		mov al,00h				;if direction is down
		mov al,ground_in
		mov bl,ground_up
		or al,bl				;check if ground_in or ground_up is set
		jnz x88
		mov al,second_down
		mov bl,second_in
		or al,bl
		mov bl,second_up
		or al,bl
		mov bl,third_down
		or al,bl
		mov bl,third_in
		or al,bl				;if(second_down || second_in || second_up || third_down || third_in) checking if any of the buttons in the floors above are pressed
		jz x88
		mov al,01h
		mov direction,al		;if yes, set direction to up
x88:	call speed_up
		mov al,00h
		mov first_down,al 		;reset first_down
		jmp exit_f

x10:	mov al,floor
		cmp al,00000010b		;check if floor is 2
		jnz x11
		mov al,slow
		cmp al,01h				;check if slow flag is set
		jnz xn
		call stop_lift			; if yes, stop and open lift
		call open_lift
		mov al,00h				; same conditions as above to close the door and move
kel2:	call keybrd
		call key_press
		cmp al,00h
		jz kel2
		mov al,00h
		mov second_up,al 		;reset second_up 				
		mov second_down,al 		;reset second_down
		call button_outside
		mov al,press_out
		cmp al,01h
		jz ke2
		mov al,door_close
		cmp al,01h
		jnz kel2
ke2:	mov al,00h
		mov door_close,al
		call close_lift
		mov al,00h
		mov slow,al
		
xn:		mov al,00h 				
		mov second_in,al 		;reset second_in
		mov al,direction
		cmp al,01h				;check if direction is up
		jnz x12
		mov al,third_in
		mov bl,third_down
		or al,bl				;if(third_down || third_in) check if the buttons in the third floor are pressed
		jnz x122
		mov al,10h
		mov direction,al		;set direction to up
x122:	mov al,00h 				
		mov second_up,al 		;reset second_up
		jmp exit_f
x12:	mov al,00h
		mov second_down,al 		;reset second_down
		mov al,ground_in
		mov bl,ground_up
		or al,bl			
		mov bl,first_down
		or al,bl
		mov bl,first_in
		or al,bl
		mov bl,first_up			;check if any of the buttons in ground floor or first floor are pressed
		or al,bl
		jnz exit_f
		mov al,third_down		
		mov bl,third_in
		or al,bl				;if not, check if third floor buttons are pressed
		jz exit_f
		mov al,01h
		mov direction,al		;if yes, set direction to up
		jmp exit_f
x11:
		call stop_lift
		mov al,third_down
		mov bl, third_in
		or al,bl
		jz x13
		call open_lift			
		mov al,00h
kel4:	call keybrd				
		call key_press
		cmp al,00h
		jz kel4
		mov al,00h
		mov third_down,al
		call button_outside
		mov al,press_out
		cmp al,01h
		jz ke3
		mov al,door_close
		cmp al,01h
		jnz kel4
ke3:	mov al,00h
		mov door_close,al
		call close_lift
x13:	mov al,00h
		mov third_in,al
		mov third_down,al
		mov al,10h
		mov direction,al		

exit_f:
		ret
coarse_fine	endp

coarse_1	proc	near
		mov al,00h
		mov cs1,al				;reset cs1
		mov al,direction
		cmp al,01h				;check if direction is up
		jnz x14
		inc floor				;inc floor if direction is up and display it
		mov al,floor
		or al,00100000b
		out 04h,al
		jmp exit_c
		
x14:	mov al,floor
		cmp al,00h				;if direction is down, check if the floor is ground
		jnz x15
		mov al,01h
		mov slow,al				;lift has to stop so set slow flag
		call slow_down			;call slow down function
		jmp exit_c
		
x15:	mov al,floor			;current direction is down
		cmp al,00000001b		;check if current floor is the first floor
		jnz x16
		mov al,first_down
		mov bl,first_in
		or al,bl				;check if first down or first in is pressed.
		jz x17
		mov al,01h
		mov slow,al				;if yes, set slow flag
		call slow_down
		jmp exit_c
x17:	mov al,ground_up
		mov bl,ground_in
		or al,bl				;if first floor down or inside lift button isnt pressed, check if the ground floor buttons are pressed
		jnz exit_c
		mov al,first_up			;if not, check if first up is pressed
		cmp al,01h
		jnz exit_c
		mov al,01h
		mov slow,al				;if yes, set slow flag
		call slow_down			;slow down lift
		jmp exit_c
				
x16:	mov al,floor
		cmp al,00000010b		;check if floor is second floor
		jnz x18
		mov al,second_down
		mov bl,second_in
		or al,bl				;check if second_down or second_in is pressed
		jz x19
		mov al,01h
		mov slow,al
		call slow_down
		jmp exit_c
x19:	mov al,ground_up
		mov bl,ground_in
		or al,bl
		mov bl,first_down
		or al,bl
		mov bl,first_in
		or al,bl
		mov bl,first_up
		or al,bl				;check if ground floor and first floor buttons are pressed
		jnz exit_c
		mov al,second_up		;if not, check if second_up is pressed
		cmp al,01h
		jnz exit_c
		mov al,01h
		mov slow,al				;if yes, set slow flag and slow down lift
		call slow_down
		jmp exit_c
		
x18:	call slow_down
		mov al,01h
		mov slow,al		
exit_c:
		ret
	
coarse_1	endp

slow_down	proc	near	;procedure to slow down the motor
mov	al,direction
	cmp	al,01h
	jnz down
	mov al,00000001b
	mov dx,10h
	out	dx,al
	jmp dt_40
down:
	
	mov	al,00000010b
	mov	dx,10h
	out	dx,al
	
;dt_50:
;	mov	al,10110010b
;	out	cr_8253,al
;	mov	al,05h   
;	out	cnt2,al
;	mov	al,00h
;	out	cnt2,al
	;delay
dt_40:
	mov	al,01010010b
	out	cr_8253,al
	mov	al,06h
	out	cnt1,al
	
	mov cx,65000
	delay1: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
	loop delay1
	

	mov	al,01010010b
	out	cr_8253,al
	mov	al,07h
	out	cnt1,al
	
	mov cx,65000
	delay2: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop;delay
	loop delay2

	mov	al,01010010b
	out	cr_8253,al
	mov	al,08h
	out	cnt1,al
	
	mov cx, 65000
	delay3: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop;delay
	loop delay3	
	

	mov	al,01010010b
	out	cr_8253,al
	mov	al,00h
	out	cnt1,al
	
	ret
	
slow_down	endp

stop_lift	proc	near
			mov al,00h
			mov slow,al				;reset slow flag
			;mov ah,7fh
			;call speed
			mov bl,floor
			and bl,00001111b
			mov al,bl
			mov 04h,al
			ret
stop_lift	endp

open_lift	proc	near
			mov al,floor
			or al,10h
			out 04h,al	
			mov al,00h
			mov door_close,al
			ret
open_lift	endp

close_lift	proc	near
			mov al,floor
			and al,0fh
			out 04h,al
	
			ret
close_lift	endp				

speed_up	proc	near ;procedure to speed up the motor.

mov al,floor
or al,20h
out 04h,al

mov	al,direction
	cmp	al,01h
	jnz dn
	mov al,00000001b
	mov dx,10h
	out	dx,al
	jmp dt_20
dn:
	
	mov	al,00000010b
	mov	dx,10h
	out	dx,al
	
	
dt_20:
	mov	al,01010010b
	out	cr_8253,al
	mov	al,08h
	out	cnt1,al
	
	mov cx, 65000
	delay4: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop	;delay
	loop delay4	

	mov	al,01010010b
	out	cr_8253,al
	mov	al,07h
	out	cnt1,al
	
	mov cx, 65000
	delay5: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop	;delay
	loop delay5	 
	
	mov	al,01010010b
	out	cr_8253,al
	mov	al,06h
	out	cnt1,al
	
	mov cx, 65000
	delay6: nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop	;delay
	loop delay6	
	

	mov	al,01010010b
	out	cr_8253,al
	mov	al,05h
	out	cnt1,al
	
	ret
speed_up	endp			

button_press	proc	near				;procedure to check if any of the lift buttons are pressed
				mov al,ground_in
				mov bl,ground_up
				or al,bl
				mov bl,first_down
				or al,bl
				mov bl,first_in
				or al,bl
				mov bl,first_up
				or al,bl
				mov bl,second_down
				or al,bl
				mov bl,second_in
				or al,bl
				mov bl,second_up
				or al,bl
				mov bl,third_down
				or al,bl
				mov bl,third_in
				or al,bl
				mov press,al
				ret
button_press	endp

button_outside	proc	near				;check if any of the outside buttons of the lift are pressed
				mov al,first_down
				mov bl,ground_up
				or al,bl
				mov bl,first_up
				or al,bl
				mov bl,second_down
				or al,bl
				mov bl,second_up
				or al,bl
				mov bl,third_down
				or al,bl
				mov press_out,al
				ret
button_outside	endp				

