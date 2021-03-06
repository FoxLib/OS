/* 
 Файл содержит указатели на системные области памяти

 0x28800 - 0x28FFF Циклический клавиатурный буфер (1919 символов)
 0x29000 Позиция последнего символа
 0x29004 (mouse x)
 0x29008 (mouse y)
 0x2900C (mouse state)
 0x29010 есть/нет изменений в ps/2 mouse

 0x29014 размер экрана по ширине
 0x29018 размер экрана по высоте

 0x2901C tss(0)
 0x29020 tss(timer)

 0x29024 Значение таймера, инкрементальный счетчик
 0x29028 сегмент GS (Graphics Segment)
 0x2902C KBD Позиция начала FIFO
 0x29030 KBD Состояние клавиш (128 клавиш) [0x29030 .. 0x290AF]
 0x290B0 Максимальный размер памяти в байтах

 0x290B4 Вершина для "event_get_free"

 0x80000 TSS (0) 104 байта
 0x80068 TSS (timer) 104 байта

=== PAGING ===
 0x00000 Каталог страниц на 4 мб
 0x81000 CR3 основной системный каталог 

*/

// -----------------------------------------------------------------------------

// Клавиатура
#define KBD_BUFFER 0x28800 // Клавиатурный буфер
#define KBD_CURSOR 0x29000 // Позиция последнего символа
#define KBD_FIFO   0x2902C // Начало первого символа
#define KBD_STATUS 0x29030 // Статусы клавиш

// Мышь
#define MPTR_X 0x29004 
#define MPTR_Y 0x29008
#define MPTR_S 0x2900C // mouse status
#define MPTR_T 0x29010 // 0 = нет изменений, 1 = есть изменения

// Экран
#define SCR_WIDTH  0x29014
#define SCR_HEIGHT 0x29018

#define TSS_SEG_MAIN   0x2901C // Сегмент TSS(0)
#define TSS_SEG_TIMER  0x29020 // TSS(Timer)

// Системный таймер
#define TIMER32_P    0x29024

// Сегмент GS:
#define GS_SEG       0x29028

// Главный TSS
#define TSS_MAIN     0x80000 // 104 байта
#define TSS_TIMER    0x80068 // ...

// Глобальная страница CR3
#define CR3_PDBR0    0x81000 
#define PHYS_MEM     0x82000 // Размер памяти (байт)

// Страница занята
#define PGU_BUSY     0x0200 

// -----------------------------------------------------------------------------
#define HM_TASK_REGISTER    0x100000 // Дескрипторы для псевдо-окон 
#define DIS_STRING_RESULT   0x110000 // Дизассемблированная строка (2048)
#define ATA_IDENTIFY        0x111000 // Описатели IDENTIFY для дисков (512 байт на диск)
#define ATA_BUFFER          0x112000 // Буфер вывода ATA
#define PARTITIONS_DATA     0x122000 // Информация о разделах

/* 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Биты PTE (Page Table Entry)
----------------------------

| 0      | P (Present - присутствие). Если 0, то страница не отображена на физическую память. Если происходит обращение 
           к неприсутствующей странице (у которой бит P = 0), то процессор генерирует исключение страничного нарушения (#PF).
           Если страница не присутствует в памяти (бит P=0), то процессор не использует все остальные биты элемента PTE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 1      | R / W (Read / Write - Чтение / Запись). Если 0, то для этой страницы разрешено только чтение, 1 - чтение и запись.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 2      | U / S (User / Supervisor - Пользователь / Система). Если 0, то доступ к странице разрешён только с нулевого уровня 
            привилегий, если 1 - то со всех
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 3      | PWT (Write-Through - Сквозная запись). Когда этот флаг установлен, разрешено кэширование сквозной записи (write-through) 
           для данной страницы, когда сброшен - кэширование обратной записи (write-back).
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 4      | PCD (Cache Disabled - Кэширование запрещено). Когда установлен, кэширование данной страницы запрещено. Кэширование страниц 
           запрещают для портов ввода/вывода, отображённых на память либо в случаях, когда кэширование не даёт выигрыша в производительности. 
           Также, кэширование запрещается при обработке исключений и отладке в ситуациях, связанных с программированием кэшей. 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 5      | A (Accessed - Доступ). Устанавливается процессором каждый раз, когда он производит обращение к данной странице. Процессор не 
           сбрасывает этот флаг - его может может сбросить программа, чтобы потом, через некоторое время определить, был ли доступ к этой странице, или нет. 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 6      | D (Dirty - Грязный). Устанавливается каждый раз, когда процессор производит запись в данную страницу. Этот флаг также не
           сбрасывается процессором и может использоваться программой, чтобы определить, была ли запись в страницу или нет. 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 7      | PAT (Page Table Attribute Index - Индекс атрибута таблицы страниц). Для процессоров, которые используют таблицу атрибутов страниц
           (PAT - page attribute table), этот флаг используется совместно с флагами PCD и PWT для выбора элемента в PAT, который выбирает тип памяти для страницы.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 8      | G (Global Page - Глобальная страница). Когда установлен, определяет глобальную страницу. Такая страница остаётся достоверной в кэшах TLB
           при перезагрузке регистра CR3 или переключении задач. Этот бит введён в Pentium Pro и работа с ним подробно описана в "Управлении кэшами".
           Для процессоров, младше Pentium Pro, этот бит зарезервирован и должен быть равен 0.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 9..11  | Доступно для использования программой. Процессор не использует эти биты.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
| 12..31 | Базовый адрес страницы - это адрес, с которого начинается страница, другими словами - это физический адрес, на который отображена данная страница.


  31                   12  11   9  8    7    6   5    4     3     2     1    0    
+-------------------------+------+---+-----+---+---+-----+-----+-----+-----+---+
| Базовый адрес страницы  | USER | G | PAT | D | A | PCD | PWT | U/S | R/W | P |
+-------------------------+------+---+-----+---+---+-----+-----+-----+-----+---+
*/