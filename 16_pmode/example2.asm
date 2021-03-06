
        org     7C00h        
        macro   brk { xchg bx, bx }
        
;-------------------------------------------------------------------------
; Определяем селекторы как константы. У всех у них биты TI = 0 (выборка
; дескрипторов производится из GDT), RPL = 00B - уровень привилегий -
; нулевой.

    Code_selector    equ  8
    Stack_selector   equ 16
    Data_selector    equ 24
    Screen_selector  equ 32

;--------------------------------------------------------------------------
    mov    bx, GDT + 8      ; Нулевой дескриптор устанавливать не будем - всё равно он не используется.
    xor    eax, eax         ; EAX = 0
    mov    edx, eax         ; EDX = 0
    push   cs               ; AX = CS = сегментный адрес текущего
    pop    ax               ; сегмента кода.

    ; EAX = физический адрес начала сегмента кода. Эта программа, работая в среде операционной системы
    ; режима реальных адресов (подразумевается, что это - MS-DOS) уже  имеет в IP смещение относительно
    ; текущего сегмента кода. Мы определим дескриптор кода для защищённого режима с таким же адресом
    ; сегмента кода,  чтобы при переходе через команду дальнего перехода фактически переход произошёл
    ; на следующую команду.

    shl    eax, 4

    ; Предел сегмента кода может быть любым, лишь бы он покрывал  весь реально существующий код.

    mov    dx, 65535
    mov    cl, 10011000b            ; Права доступа сегмента кода (P = 1,
                                    ; DPL = 00b, S = 1, тип = 100b, A = 0)
    call   set_descriptor           ; Конструируем дескриптор кода.
    lea    dx, [Stack_seg_start]    ; EDX = DX = начало стека (см. саму метку).
    add    eax, edx                 ; EAX уже содержит адрес начала сегмента
                                    ; кода, сегмент стека начнётся с последней
                                    ; метки программы Stack_seg_start.
    mov    dx, 1024                 ; Предел стека. Также любой (в данном
                                    ; примере), лишь бы его было достаточно.
    mov    cl, 10010110b            ; Права доступа дескриптора сегмента
                                    ; стека (P = 1, DPL = 00b, S = 1,
                                    ; тип = 011b, A = 0).
    call   set_descriptor           ; Конструируем дескриптор стека.
    xor    eax, eax                 ; EAX = 0
    mov    ax, ds
    shl    eax, 4                   ; EAX = физический адрес начала сегмента данных.
    xor    ecx, ecx                 ; ECX = 0
    lea    cx, [PMode_data_start]   ; ECX = CX
    add    eax, ecx                 ; ECX = физический адрес начала сегмента данных

    lea    dx, [PMode_data_end]

    sub    dx, cx           ; DX = PMode_data_end - PMode_data_start (это
                            ; размер сегмента данных, в данном примере
                            ; он равен 26 байтам). Этот размер мы и
                            ; будем использовать как предел.
    mov    cl, 10010010b    ; Права доступа сегмента данных (P = 1,
                            ; DPL = 00b, S = 1, тип = 001, A = 0).
    call   set_descriptor   ; Конструируем дескриптор данных.
    mov    eax, 0b8000h     ; Физический адрес начала сегмента
                            ; видеопамяти для цветного текстового
                            ; режима 80 символов, 25 строк
                            ; (используется по умолчанию в MS-DOS).
    mov    edx, 4000        ; Размер сегмента видеопамяти (80*25*2 = 4000).
    mov    cl, 10010010b    ; Права доступа - как сегмент данных
    call   set_descriptor   ; Конструируем дескриптор сегмента видеопамяти.

; Устанавливаем GDTR:

    xor    eax, eax         ; EAX = 0
    mov    edx, eax         ; EDX = 0

    mov    ax, ds
    shl    eax, 4           ; EAX = физический адрес начала сегмента данных.
    lea    dx, [GDT]
    add    eax, edx         ; EAX = физический адрес GDT
    mov    [GDT_adr], eax   ; Записываем его в поле адреса образа GDTR.
    mov    dx,39            ; Предел GDT = 8 * (1 + 4) - 1
    mov    [GDT_lim], dx    ; Записываем его в поле предела образа GDTR.
    cli                     ; Запрещаем прерывания. Для того, чтобы прерывания
                            ; работали в защищённом режиме их нужно специально
                            ; определять, что в данном примере не делается.
    lgdt   [GDTR]           ; Загружаем образ GDTR в сам регистр GDTR.

; Переходим в защищённый режим:

    mov    eax, cr0
    or     al, 1
    mov    cr0, eax

; Процессор в защищённом режиме!

    db     0eah             ; Этими пятью байтами кодируется команда
    dw     P_Mode_entry     ; jmp far Code_selector : P_Mode_entry
    dw     Code_selector

; Подразумевается, что файл находится
; в том же каталоге, что и example2.asm

    include "pmode.lib.asm"

;-----------------------------------------------------------------------

P_Mode_entry:

; В CS находится уже не сегментный адрес сегмента кода, а селектор его
; дескриптора.

; Загружаем сегментные регистры. Это обеспечит правильную работу программы
; на любом 32-разрядном процессоре.

    mov    ax, Screen_selector
    mov    es, ax
    mov    ax, Data_selector
    mov    ds, ax
    mov    ax, Stack_selector
    mov    ss, ax
    mov    sp, 0

; Выводим ZS-строку:

; DS:BX = указатель на начало ZS-строки. Адрес
;  сегмента данных определён по метке
;  PMode_data_start, а строка начинается сразу после
;  этой метки, её смещение от метки равно 0,
;  следовательно, это и будет смещение от начала
;  сегмента данных.

    mov    bx, 0
    mov    di, 480  ; Выводим ZS-строку со смещения 480 в
                    ;  видеопамяти (оно соответствует началу
                    ;  3-й строки на экране в текстовом режиме).
    call    putzs

; Зацикливаем программу:

    jmp    $

;--------------------------------------------------------------------------
; Образ регистра GDTR:

GDTR:
GDT_lim   dw    ?
GDT_adr   dd    ?

;--------------------------------------------------------------------------
GDT:
    dd    ?,?       ; 0-й дескриптор
    dd    ?,?       ; 1-й дескриптор (кода)
    dd    ?,?       ; 2-й дескриптор (стека)
    dd    ?,?       ; 3-й дескриптор (данных)
    dd    ?,?       ; 4-й дескриптор (видеопамяти)
;--------------------------------------------------------------------------
; Начало сегмента данных для защищённого режима.

PMode_data_start:

    db    "I am in protected mode!!!",0    ; ZS-строка для вывода в P-Mode.

;--------------------------------------------------------------------------
PMode_data_end:         ; Конец сегмента данных.
;--------------------------------------------------------------------------
    db    1024 dup (?)  ; Зарезервировано для стека.

Stack_seg_start:        ; Последняя метка программы - отсюда будет расти стек.
