.model small
.stack 1000h
.data
  newline db 0dh, 0ah, '$'
  snakePosX db 10
  snakePosY db 20
  exitFlag db 0
  boardStartX db 15
  boardStartY db 10
  boardWidth db 40
  boardHeight db 40
  snakeDirection db DIRECTION_EAST

  ;keys
  ESCAPE EQU 01h
  UP_ARROW EQU 4Bh
  DOWN_ARROW EQU 50h
  LEFT_ARROW EQU 48h
  RIGHT_ARROW EQU 4Dh

  ;directions
  DIRECTION_NORTH EQU 0
  DIRECTION_EAST EQU 1
  DIRECTION_SOUTH EQU 2
  DIRECTION_WEST EQU 3

PrintNewLine macro
  mov ah,09h
  mov dx,offset newline
  int 21h
endm

PrintHorizontalWall macro
  local @@agn
  mov ch,0
  mov cl,boardWidth
  inc cl
  @@agn:
    mov ah,02h
    mov dl,'='
    int 21h
  loop @@agn
endm

MoveCursor macro x, y
  push ax
  push dx
  mov dh,y
  mov dl,x
  mov bh,0h
  mov ah,02h
  int 10h
  pop dx
  pop ax
endm

PrintSnakeHead macro
  MoveCursor snakePosX, snakePosY
  mov ah,02h
  mov dl,'@'
  int 21h
endm

Sleep macro
  mov ah, 29h
  int 21h
endm

PrintChar macro c
  push ax
  mov ah,02h
  mov dl,c
  int 21h
  pop ax
endm

PrintBoard macro
  push ax
  push cx

  MoveCursor boardStartX,boardStartY
  PrintHorizontalWall

  mov ah,boardStartX
  mov al,boardStartY
  mov ch,0
  mov cl,boardHeight
  PrintWalls:
    inc al
    MoveCursor ah,al
    PrintChar '|'
    push ax
    add ah,40
    MoveCursor ah,al
    pop ax
    PrintChar '|'
  loop PrintWalls

  mov al,boardStartY
  add al,40
  MoveCursor boardStartX,al
  PrintHorizontalWall

  pop cx
  pop ax
endm

MoveSnakeHead macro
  MoveCursor snakePosX, snakePosY
  PrintChar ' '
  mov al,[snakeDirection]

  cmp al,DIRECTION_EAST
  je moveEast

  cmp al,DIRECTION_WEST
  je moveWest

  mov al,[snakeDirection]

  cmp al,DIRECTION_SOUTH
  je moveSouth

  cmp al,DIRECTION_NORTH
  je moveNorth

  moveEast:
    mov al,[snakePosX]
    inc al
    mov [snakePosX],al
    jmp moveSnakeEnd

  moveSouth:
    mov al,[snakePosY]
    inc al
    mov [snakePosY],al
    jmp moveSnakeEnd

  moveWest:
    mov al,[snakePosY]
    dec al
    mov [snakePosY],al
    jmp moveSnakeEnd

  moveNorth:
    mov al,[snakePosX]
    dec al
    mov [snakePosX],al
    jmp moveSnakeEnd

  moveSnakeEnd:
endm

HideCursor macro
  mov ah,01
  mov ch,32
  int 10h
endm

.code

ExecuteIfEqual proc var, val, procName
  mov ax,[var]
  cmp ax,val
  jne ExecuteIfEqualEnd
  call procName

  ExecuteIfEqualEnd:
  ret
endp

Sleep2 proc ms
  ; Convert milliseconds to microseconds
  mov cx,4000
  mul cx             ; DX:AX = milliseconds * 1000 (in microseconds)
  mov cx,dx
  mov dx,ax
  mov ah,86h
  mov al,0           ; Important: set AL to 0
  int 15h
  ret
Sleep2 endp

CLS proc
  push cx
  push dx
  push bx

  mov ah, 06h     ; function 06h: scroll active page up
  mov al, 00h     ; scroll 0 lines (clears the entire window)
  mov bh, 07h     ; attribute (color): 07h is standard white on black
  mov cx, 0000h   ; upper-left corner (row 0, col 0)
  mov dx, 4f4fh   ; lower-right corner (row 24, col 79)
  int 10h         ; call bios video service

  ; set cursor to home (0,0) - important for a clean start
  mov ah, 02h     ; function 02h: set cursor position
  mov bh, 00h     ; display page 0
  mov dh, 00h     ; row 0
  mov dl, 00h     ; column 0
  int 10h         ; call bios video service

  pop bx
  pop dx
  pop cx
  ret
CLS endp

HandleInput proc
  mov ah,01h ; is there a key to read?
  int 16h
  jz HandleInputEnd

  mov ah,00h
  int 16h

  cmp ah,ESCAPE
  je EscapePressed

  cmp ah,UP_ARROW
  je UpArrowPressed

  cmp ah,DOWN_ARROW
  je DownArrowPressed

  cmp ah,LEFT_ARROW
  je LeftArrowPressed

  cmp ah,RIGHT_ARROW
  je RightArrowPressed

  jmp HandleInputEnd

  UpArrowPressed:
    mov [snakeDirection],DIRECTION_NORTH
    jmp HandleInputEnd

  RightArrowPressed:
    mov [snakeDirection],DIRECTION_EAST
    jmp HandleInputEnd

  DownArrowPressed:
    mov [snakeDirection],DIRECTION_SOUTH
    jmp HandleInputEnd

  LeftArrowPressed:
    mov [snakeDirection],DIRECTION_WEST
    jmp HandleInputEnd

  EscapePressed:
    mov [exitFlag],1
    jmp HandleInputEnd

  HandleInputEnd:
    ret
HandleInput endp

IsTouchingWall Proc
  mov al,boardStartX
  cmp snakePosX,al
  je WallIsTouched

  mov al,boardStartY
  cmp snakePosY,al
  je WallIsTouched

  mov ah,0
  mov al,boardStartX
  add al,boardWidth
  cmp snakePosX,al
  jge WallIsTouched

  mov ah,0
  mov al,boardStartY
  add al,boardHeight
  cmp snakePosY,al
  jge WallIsTouched

  jmp Exit

  WallIsTouched:
    mov al,1

  Exit:
    ret
IsTouchingWall endp

main proc
  mov ax,@DATA
  mov ds,ax
  HideCursor
  call CLS
  PrintBoard

  mov al,boardStartX
  add al,2
  mov [snakePosX],al

  mov al,boardHeight
  shr al,1
  add al,boardStartY
  mov [snakePosY],al

  GameLoop:
    PrintSnakeHead
    call IsTouchingWall
    cmp al,1
    je Death

    mov ax,10
    call Sleep2
    call HandleInput
    cmp exitFlag,1
    je GameLoopEnd

    MoveSnakeHead
    jmp GameLoop
  Death:
    ; print death and wait for enter
  GameLoopEnd:

  call CLS
  mov ax,4c00h
  int 21h

main endp
end main
