; #########################################################################

	.486                      ; create 32 bit code
	.model flat, stdcall      ; 32 bit memory model
	option casemap :none      ; case sensitive

; #########################################################################

	include \masm32\include\windows.inc
	include \masm32\include\user32.inc
	include \masm32\include\kernel32.inc
	include \MASM32\INCLUDE\shell32.inc
	include \MASM32\INCLUDE\Comctl32.inc
	include \MASM32\INCLUDE\comdlg32.inc

	includelib \masm32\lib\user32.lib
	includelib \masm32\lib\kernel32.lib
	includelib \MASM32\LIB\shell32.lib
	includelib \MASM32\LIB\Comctl32.lib
	includelib \MASM32\LIB\comdlg32.lib

; #########################################################################

	createUI 		PROTO :DWORD
	clear_buffers 	PROTO :DWORD,:DWORD
	base64decode 	PROTO :DWORD,:DWORD,:DWORD
	base64encode 	PROTO :DWORD,:DWORD,:DWORD


.data
	hInstance	dd 0
	e			dd 0
	b_enc		dd 0
	b_dec		dd 0
	b_opn		dd 0


	base64table db 43 dup (255)
	db 62,255,255,255,63,52,53,54,55,56,57,58,59,60,61,255
	db 255,255,0,255,255,255,0,1,2,3,4,5,6,7,8,9,10,11,12,13
	db 14,15,16,17,18,19,20,21,22,23,24,25,255,255,255,255
	db 255,255,26,27,28,29,30,31,32,33,34,35,36,37,38
	db 39,40,41,42,43,44,45,46,47,48,49,50,51
	db 132 dup (255)

	alphabet	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


.code
	szClassName	db "base64 endcoder/decoder", 0
	b64			db "EDIT", 0
	btnClass	db "BUTTON",0
	lpText_enc	db "encode",0
	lpText_dec	db "decode",0
	lpText_opn	db "open it",0
	tmp1		db "user32.dll",0
	tmp2		db "SetProcessDPIAware",0
	open 		db "open",0

  start:

; #########################################################################
;
; Main
;
; #########################################################################

Main proc

	local msg      :MSG
	local wc       :WNDCLASSEX

	; add support for high DPI displays (ie, remove blurriness)
	invoke LoadLibrary,offset tmp1
	push eax
	invoke GetProcAddress, eax, offset tmp2
	call eax
	pop eax
	invoke FreeLibrary,eax

	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke InitCommonControls

	xor edi, edi
	mov esi, 400000h

	mov ebx, OFFSET szClassName

	invoke LoadCursor,edi,IDC_ARROW

	mov wc.cbSize,         sizeof WNDCLASSEX
	mov wc.style,          CS_VREDRAW or CS_HREDRAW
	mov wc.lpfnWndProc,    offset WndProc
	mov wc.cbClsExtra,     edi
	mov wc.cbWndExtra,     edi
	mov wc.hInstance,      esi
	mov wc.hbrBackground,  COLOR_BTNFACE+1
	mov wc.lpszMenuName,   edi
	mov wc.lpszClassName,  ebx
	mov wc.hIcon,          edi
	mov wc.hCursor,        eax
	mov wc.hIconSm,        edi

	invoke RegisterClassEx, ADDR wc

	mov ecx, CW_USEDEFAULT

	invoke CreateWindowEx, WS_EX_TOPMOST,ebx,ebx,
                           WS_OVERLAPPEDWINDOW,
                           ecx,edi,
                           700,200,
                           edi,edi,
                           esi,edi

	invoke ShowWindow,eax,SW_SHOWNORMAL

	StartLoop:
	invoke GetMessage,ADDR msg,NULL,0,0
	cmp eax, 0
	je ExitLoop
	invoke TranslateMessage, ADDR msg
	invoke DispatchMessage,  ADDR msg
	jmp StartLoop
	ExitLoop:

	mov eax, msg.wParam
	ret

Main endp


; #########################################################################
;
; clear_buffers
;
; #########################################################################

clear_buffers proc buf1 :DWORD, buf2: DWORD

	invoke RtlZeroMemory, buf1, 2048
	invoke RtlZeroMemory, buf2, 2048
	ret

clear_buffers endp


; #########################################################################
;
; WndProc
;
; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

	local src[2048]:BYTE
	local dst[2048]:BYTE
	local btn_top:DWORD
	local win_width:DWORD
	local txt_height:DWORD
	local btn_width:DWORD
	local btn_left:DWORD

	.if uMsg == WM_COMMAND
		.if wParam == 500
			invoke clear_buffers, addr src, addr dst
			invoke SendMessage, e, WM_GETTEXT, 2048, addr src
			invoke base64encode, addr src, addr dst, eax
			invoke SendMessage, e, WM_SETTEXT, 0, addr dst
		.elseif wParam == 501
			invoke clear_buffers, addr src, addr dst
			invoke SendMessage, e, WM_GETTEXT, 2048, addr src
			invoke base64decode, addr src, addr dst, eax
			invoke SendMessage, e, WM_SETTEXT, 0, addr dst
		.elseif wParam == 502
			invoke clear_buffers, addr src, addr dst
			invoke SendMessage, e, WM_GETTEXT, 2048, addr src
			.if eax > 0
				invoke ShellExecute, 0, addr open, addr src, 0, 0, SW_SHOWNORMAL
			.endif
		.endif
	.elseif uMsg == WM_CREATE
		invoke createUI, hWin
		;ret
	.elseif uMsg == WM_SIZE	; responsive UX in assembly!
		mov eax, lParam
		mov edx, eax
		and eax, 0ffffh
		shr edx, 16
		
		sub edx, 50
		mov btn_top, edx
		mov txt_height, edx
		mov win_width, eax
		xor edx, edx
		mov ebx, 3
		div ebx
		mov btn_width, eax
		shl eax, 1
		mov btn_left, eax

		invoke MoveWindow, e, 0, 0,  win_width, txt_height, TRUE
		invoke MoveWindow, b_enc, 0, btn_top, btn_width, 50, TRUE
		invoke MoveWindow, b_dec, btn_width, btn_top, btn_width, 50, TRUE
		invoke MoveWindow, b_opn, btn_left, btn_top, btn_width, 50, TRUE

	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL
		mov eax, 0
		ret
	.endif

	invoke DefWindowProc,hWin,uMsg,wParam,lParam
	ret

WndProc endp


; #########################################################################
;
; createUI
;
; #########################################################################

createUI proc hParent:DWORD

	invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset b64,0,
				WS_CHILD or WS_VISIBLE or WS_VSCROLL or \
				ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL,
				0,0,0,0,
				hParent,700,hInstance,NULL
				
	mov e, eax

	invoke CreateWindowEx,0,
			offset btnClass,offset lpText_enc,
			WS_CHILD or WS_VISIBLE,
			0,0,0,0,
			hParent,500,hInstance,NULL
	mov b_enc, eax

	invoke CreateWindowEx,0,
			offset btnClass,offset lpText_dec,
			WS_CHILD or WS_VISIBLE,
			0,0,0,0,
			hParent,501,hInstance,NULL
	mov b_dec, eax

	invoke CreateWindowEx,0,
			offset btnClass,offset lpText_opn,
			WS_CHILD or WS_VISIBLE,
			0,0,0,0,
			hParent,502,hInstance,NULL
	mov b_opn, eax

	xor eax,eax
	ret

createUI endp


; #########################################################################
;
; base64 decoding
;
; #########################################################################

base64decode PROC source:DWORD, destination:DWORD, sourcelen:DWORD 
	push esi 
	push edi 
	push ebx 

	mov esi, source	; esi <- source 
	mov edi, destination	; edi <- destination 
	mov ecx, sourcelen 
	shr ecx, 2 
	cld 

	;-------------[decoding part]--------------- 

	@@outer_loop: 
	push ecx 
	mov ecx, 4 
	xor ebx, ebx 
	lodsd 
	@@inner_loop: 
		push eax 
		and eax, 0ffh
		mov al, byte ptr [offset base64table+eax]
		cmp al, 255
		je @@invalid_char
		shl ebx, 6 
		or bl, al
		@@skip:
		pop eax 
		shr eax, 8 
		dec ecx 
		jnz @@inner_loop
	mov eax, ebx 
	shl eax, 8 
	xchg ah, al 
	ror eax, 16 
	xchg ah, al 
	stosd 
	dec edi 
	pop ecx 
	dec ecx 
	jnz @@outer_loop 
	xor eax, eax 
	jmp @@decode_done 

	;------------------------------------------- 

	@@invalid_char: 
	mov eax, -1 
	@@decode_done: 
	pop ebx 
	pop edi 
	pop esi 
	ret 
base64decode ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; base64 encoding
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

base64encode PROC source:DWORD, destination:DWORD, sourcelen:DWORD

	.if sourcelen == 0
		ret
	.endif

	push edi 
	push esi 
	push ebx 
	mov esi, source 
	mov edi, destination

	@@base64loop: 
	xor eax, eax
	.if sourcelen == 1
		lodsb	;source ptr + 1 
		mov ecx, 2	;bytes to output = 2 
		mov edx, 03D3Dh	;padding = 2 byte 
		dec sourcelen	;length - 1 
	.elseif sourcelen == 2 
		lodsw	;source ptr + 2 
		mov ecx, 3	;bytes to output = 3 
		mov edx, 03Dh	;padding = 1 byte 
		sub sourcelen, 2	;length - 2 
	.else 
		lodsd 
		mov ecx, 4	;bytes to output = 4 
		xor edx, edx	;padding = 0 byte 
		dec esi	;source ptr + 3 (+4-1) 
		sub sourcelen, 3	;length - 3 
	.endif

	xchg al,ah	; flip eax completely 
	rol eax, 16	; can this be done faster
	xchg al,ah	; ?? 

	@@: 
	push eax 
	and eax, 0FC000000h	;get the last 6 high bits 
	rol eax, 6	;rotate them into al 
	mov al, byte ptr [offset alphabet+eax]	;get encode character 
	stosb	;write to destination 
	pop eax 
	shl eax, 6	;shift left 6 bits 
	dec ecx 
	jnz @B	;loop 

	cmp sourcelen, 0 
	jnz @@base64loop	;main loop 

	mov eax, edx	;add padding and null terminate 
	stosd	; " " " " " 

	pop ebx 
	pop esi 
	pop edi 
	ret

base64encode endp


end start
