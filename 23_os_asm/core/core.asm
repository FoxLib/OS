
; Простановка редиректов
; ----------------------------------------------------------------------

irq_init: 

        ; Отключение APIC
        mov     ecx, 0x1b
        rdmsr
        and     eax, 0xfffff7ff
        wrmsr

        ; Выполнение запросов
        mov     ecx, 10
        xor     edx, edx
        mov     esi, .data
@@:     lodsw
        mov     dl, al
        mov     al, ah
        out     dx, al
        jcxz    $+2
        jcxz    $+2
        loop    @b
        ret

.data:  ; Данные для отправки команд
        db      PIC1_COMMAND, ICW1_INIT + ICW1_ICW4
        db      PIC2_COMMAND, ICW1_INIT + ICW1_ICW4
        db      PIC1_DATA,    0x20
        db      PIC2_DATA,    0x28
        db      PIC1_DATA,    0x04
        db      PIC2_DATA,    0x02
        db      PIC1_DATA,    ICW4_8086
        db      PIC2_DATA,    ICW4_8086
        db      PIC1_DATA,    0xFF xor (IRQ_TIMER or IRQ_KEYB or IRQ_FDC or IRQ_CASCADE)
        db      PIC2_DATA,    0xFF xor (IRQ_PS2)

; Инициализация IVT
; Для IRQ используются "обертки" - устанавливаются ссылки в .irq_X
; ----------------------------------------------------------------------

ivt_init:

        ; Очистка IVT
        mov     eax, .unk
        xor     edi, edi
        mov     ecx, 256
@@:     call    .make
        loop    @b

        ; Установка ссылок на обработчики IRQ #n
        mov     cx,  16
        mov     eax, ivt.vec0
        mov     edi, $20 shl 3
@@:     call    .make
        add     eax, (ivt.vec1 - ivt.vec0)
        loop    @b
        ret

.make:  ; eax - адрес прерывания, edi - адрес ivt
        mov     [edi+0], eax
        mov     [edi+4], eax
        mov     [edi+2], dword $8E000010
        add     edi, 8
        ret

; Ошибка вызова несуществующего прерывания. Ничегошеньки не делать.
.unk:   iretd

; Инициализация главной TSS
; ----------------------------------------------------------------------

tss_init:

        mov     [tss.iobp], word 104
        mov     ax, 18h
        ltr     ax
        ret

; Инициализация важных устройств
; ----------------------------------------------------------------------

tik_init:

        mov     [irq_timer], 0

        ; Часы на 100 мгц
        mov     al, $34
        out     $43, al
        mov     al, $9b
        out     $40, al
        mov     al, $2e
        out     $40, al
        ret

; Поиск размера памяти и установка страниц -> TSS.cr3
; ----------------------------------------------------------------------

mem_init:

        ; Тест размера памяти
        mov     ecx, 32             ; Бинарный поиск на 2^32
        mov     esi, LOW_MEMORY
        mov     edi, $BFFFFFFF      ; $c0000000 hardware
.rept:  mov     ebx, esi            ; ebx = (esi + edi) >> 1
        add     ebx, edi
        rcr     ebx, 1
        mov     al, [ebx]           ; Тест изменений
        xor     [ebx], byte $55
        cmp     [ebx], al
        cmove   edi, ebx            ; Уменьшить верхнюю
        cmovne  esi, ebx            ; Увеличить нижнюю
        mov     [ebx], al
.next:  loop    .rept
        mov     [mem_size], edi     ; Тут будет верхняя граница

        ; Разметка PDBR
        mov     ecx, edi
        shr     ecx, 22             ; Кол-во 4-мб страниц
        mov     edi, LOW_MEMORY     ; Очистить PDBR
        push    edi ecx
        mov     ecx, 1024
        xor     eax, eax
        rep     stosd
        pop     ecx edi
        mov     eax, LOW_MEMORY + $1003 ; Каталоги c правами R/W=1, P=1
@@:     stosd
        add     eax, $1000
        loop    @b

        ; Разметка каталогов
        mov     ecx, [mem_size]
        shr     ecx, 12
        mov     ecx, ecx
        mov     ecx, $8000
        mov     edi, LOW_MEMORY + $1000
        mov     eax, $000003
@@:     stosd
        add     eax, $1000
        loop    @b

        ; Добавление региона UMMP (битовая маска занятости)
        mov     [ummp], edi
        mov     ecx, [mem_size]
        shr     ecx, (12 + 3)           ; 1 байт описывает 2^15 памяти
        push    edi ecx
        shr     ecx, 2
        xor     eax, eax
        rep     stosd
        pop     ecx edi
        add     edi, ecx

        ; Локальная память для задач ядра
        mov     [appsmem], START_MEM
        mov     [dynamic], edi

        ; Включение страничной организации
        mov     eax, LOW_MEMORY
        mov     cr3, eax
        mov     [tss.cr3], eax

        ; Переключить на страницы
        mov     eax, cr0
        bts     eax, 31
        mov     cr0, eax

        ret

; Перенос GDT в другое место
; ----------------------------------------------------------------------

gdt_init:

        mov     esi, GDT
        mov     edi, [dynamic]
        add     [dynamic], dword $10000     ; Выделить 64 кб
        push    edi edi
        xor     eax, eax
        mov     ecx, $4000
        rep     stosd
        pop     edi
        mov     cx, 4*2
        rep     movsd
        pop     edi

        ; Новый GDT. Сохранить размер
        mov     [GDTR + 2], edi
        lgdt    [GDTR]

        ; Перезагрузка сегментов
        mov     ax, $0008
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        ret
