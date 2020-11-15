; ----------------------------------------------------------------------
; ЧАСТЬ 2. Загрузочный менеджер
; 
; Загрузка приложений через FAT32 и их запуск
; ----------------------------------------------------------------------

    org 0x0010

    macro   brk { xchg bx, bx }

    ; --------------------------------
    ; Переместить себя в Himem
    ; --------------------------------

    xor     ax, ax
    mov     ds, ax
    dec     ax
    mov     es, ax
    mov     cx, 16384   ; 2 x 16kb
    mov     si, 0x0800
    mov     di, 0x0010
    rep     movsw
    jmp     0xffff : himem

himem:

    ; Новые сегменты
    mov     ds, ax
    mov     es, ax
    mov     ss, ax

    ; --------------------------------
    ; Здесь мы уже работаем в HiMem
    ; --------------------------------

    mov     ax, $0700
    call    display_clear

    ; Нарисовать рамку
    mov     ax, $0000
    mov     bx, $194F
    call    display_paintfm

    ; Заголовки
    mov     ax, $0001
    mov     si, app.title
    call    display_printsz

    mov     ax, $0036
    mov     si, app.info
    call    display_printsz

    ; Вертикальная линия с информацией
    mov     ax, $0034
    mov     cx, 25
    call    display_hline
    
    ; ----
    
e:  jmp     $    

; ----------------------------------------------------------------------
; МОДУЛИ
; ----------------------------------------------------------------------

    include "modules/display.asm"

; ----------------------------------------------------------------------
; ДАННЫЕ
; ----------------------------------------------------------------------

app:

    .title db " File bootstarter ", 0
    .info db " Information ", 0
