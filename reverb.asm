%include "io.inc"

%include "/home/alejandro/Desktop/fun.asm"

section .data
    inAudioFile    db  'audio.txt', 0h            ; name of input audio file
    outAudioFile   db  'audio-reverb.txt', 0h     ; name of output audio file
    
section .bss
    ; file management
    inDescr        resb     4     ; in file descriptor
    outDescr       resb     4     ; out file descriptor
    lineIn         resb     7     ; store input audio line
    
    ; sample information
    x_n            resd     1     ; current input sample
    y_n            resd     1     ; current output sample
    y_n_temp       resd     1     ; current output sample copy for string conversion
    k              resd     1     ; k parameter
    alpha          resd     1     ; alpha parameter
    
    ; fixed point arithmetic
    op1            resd     1     ; operand 1 of multiplication
    op2            resd     1     ; operand 2 of multiplication
    
    isNegRes       resb     1     ; negative result flag
    
    high           resd     1     ; high result of multiplication
    low            resd     1     ; low result of multiplication
   
    mid1           resd     1     ; mid sub term 1 (a x d)
    mid2           resd     1     ; mid sub term 2 (b x c)
    mid            resd     1     ; medium result of multiplication
    
    resultMulti    resd     1     ; multiplication result value

section .text
global CMAIN
CMAIN:
    mov ebp, esp; for correct debugging
    
    call    rwAll                 ; read write loop
    
    call    closeFiles            ; close files
    
    call    exit                  ; exit function
    
    
; ------
; applyOperation()
; applies operration to x_n and stores it in y_n
applyOperation:
    push    eax                  ; save eax
    push    ebx
    
    ; load operands on op1 and op2
    mov     eax, 0               ; clear eax
    mov     ebx, 0               ; clear ebx
    mov     eax, op1             ; op1 memory pos on eax
    mov     ebx, [x_n]           ; input sample value on ebx
    mov     [eax], ebx           ; move input sample to op1 memory pos
    
    mov     eax, op2             ; op2 memory pos on eax
    mov     ebx, [alpha]         ; alpha value on ebx
    mov     [eax], ebx           ; move alpha value to op2 memory pos
    
    call    multiply             ; multiplies operands op1 and op2 on resultMulti
    
    ; get result
    mov     eax, [resultMulti]
    mov     [y_n], eax           ; move eax result of operation to y_n position
    
    pop     ebx
    pop     eax                  ; restore eax
    
    
    
    ret
    
    
; ------
; calculateFPAMulti()
; Calculates fixed point arithmetic multiplication according to algorithm with operands on op1 and op2
calculateFPAMulti:
    mov     ecx, [op1]            ; load op1 on eax
    mov     edx, [op2]            ; load op2 on ebx
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
calculateHigh:
    ; calculate high
    mov     al, ch                ; move integer part of op1 (ch) to al
    mov     bl, dh                ; move integer part of op2 (dh) to bl
    
    push    edx                   ; save edx (operand 2) for multiplication
    mul     ebx                   ; multiply a from algorithm (eax-al) with c from algorithm (ebx-bl)
    pop     edx                   ; restore edx (operand 2)
    mov     word[high], ax        ; store high on variable
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
calculateLow:
    ; calculate low
    mov     al, cl                ; move float part of op1 (cl) to al
    mov     bl, dl                ; move float part of op2 (dl) to bl
    
    push    edx                   ; save edx (op2) for multiplication
    mul     ebx                   ; multiply b from algorithm (eax-al) with d from algorithm (ebx-bl)
    pop     edx                   ; restore edx (op2)
    mov     word[low], ax         ; store low on variable
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
   
   
calculateMid:
    ; calculate mid
    ; first mid term (a x d)
    mov     al, ch                ; move integer part of op1 (ch) to al
    mov     bl, dl                ; move float part of op2 (dl) to bl
    
    push    edx                   ; save edx (op2) for multiplication
    mul     ebx                   ; multiply a from algorithm (eax-al) with d from algorithm (ebx-bl)
    pop     edx                   ; restore edx (op2)
    mov     word[mid1], ax        ; store mid1 sub term (a x d) on memory pos
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
    ; second mid term (b x c)
    mov     al, cl                ; move float part of op1 (cl) to al
    mov     bl, dh                ; move integer part of op2 (dh) to bl
    
    push    edx                   ; save edx (op2) for multiplication
    mul     ebx                   ; multiply b from algorithm (eax-al) with c from algorithm (ebx-bl)
    pop     edx                   ; restore edx (op2)
    mov     word[mid2], ax        ; store mid1 sub term (a x d) on memory pos
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
    ; add both mid terms
    mov     ax, [mid1]            ; move first mid term to ax
    mov     bx, [mid2]            ; move second mid term to bx
    add     eax, ebx              ; add both mid terms
    mov     dword[mid], eax       ; store mid result on mid variable
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
shiftHighLow:
    ; left shift high by 8
    mov     ebx, [high]           ; move high to eax
    mov     cl, 8                 ; move 8 to bl (shift value)
    shl     ebx, cl               ; shift eax (high) by bl (8)
    mov     word[high], bx        ; store new shifted high value
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
    ; right shift low by 8
    mov     ebx, [low]            ; move low to eax
    mov     cl, 8                 ; move 8 to bl (shift value)
    shl     ebx, cl               ; shift eax (low) by bl (8)
    mov     word[low], bx         ; store new shifted low value
    
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
addTerms:
    ; load terms to add
    mov     eax, [low]            ; move low to eax
    mov     ebx, [mid]            ; move mid to ebx    
    mov     ecx, [high]           ; move high to ecx
    
    ; add stuff
    add     eax, ebx              ; add low + mid on eax
    add     eax, ecx              ; add high + low + mid on eax
    
    ; store result
    mov     [resultMulti], eax    ; store result on variable
    
    ret
    
; ------
; checkResultNeg()
; Check if result of multiplication needs to be negativve
checkResultNeg:
    mov     ebx, 0                ; clear ebx
    mov     bl, byte[isNegRes]    ; move is negative flag to bl
    
    cmp     ebx, 1                ; check negative flag
    jz      applyTC               ; apply two's complement, result should be negative
    ret
    
applyTC:
    xor     eax, 0xffff           ; apply xor with 1111 1111 1111 1111 to switch (1-0) and (0-1)
    add     eax, 1                ; according to TC rules
    ret
    
; ------
; closeFiles()
; Close txt files
closeFiles:
    ; close input file
    mov     ebx, [inDescr]       ; move descriptor to ebx
    mov     eax, 6               ; kernel op code 6 sys_close
    int     80h                  ; os execute
    
    ; close output file
    mov     ebx, [outDescr]      ; move descriptor to ebx
    mov     eax, 6               ; kernel op code 6 sys_close
    int     80h                  ; os execute
    
    ret
    
    
; ------
; void exit()
; Exit program and restore resources    
exit:
    mov     ebx, 0                ; return 0 status on exit - 'No Errors'
    mov     eax, 1                ; kernel op code 1 sys_exit
    int     80h                   ; os execute
    
    ret
    
    
; ------
; loadInput()
; Converts ASCII to num and lods it in input x_n
loadInput:
    mov     edx, lineIn           ; move current line pos to edx
    mov     eax, 0                ; set eax on 0
    mov     ebx, x_n              ; move x_n pos to ebx
    mov     [ebx], eax            ; move a 0 in the current sample memory pos
    
    mov     ebx, 10000            ; set ebx multiplier to 10000
    mov     ecx, 0                ; mov ecx to 0 (result)
    
loadInputAux: 
    mov     eax, 0                ; move a 0 to eax to restart register
    mov     al, byte[edx]         ; move in al (eax) a byte in post edx (line in start)
    
    cmp     eax, 13               ; compare number in eax to 13 to determine end of num in lineIn
    jz      saveAscii             ; break if analyzed byte is 0d (end of number)
    
    sub     eax, 48               ; substract 48 to get number on eax
    
    push    edx                   ; save edx
    mul     ebx                   ; multiply eax number with ebx multiplier
    add     ecx, eax              ; add eax (number in dec) in ebx (result)
    pop     edx                   ; restore edx
    
    ; divide multiplier by 2
    push    eax                   ; store eax
    mov     eax, ebx              ; move ebx numerator (multiplier) to eax
    push    edx
    mov     edx, 0                ; set edx to 0 to avoid division issues
    mov     ebx, 10               ; denominator on ebx
    div     ebx                   ; divide eax (multiplier) by ebx (10)
    mov     ebx, eax              ; restore eax to ebx
    pop     edx                   ; restore edx
    pop     eax                   ; restore eax
    
    inc     edx                   ; next memory position in edx
    
    jmp     loadInputAux          ; continue loop
    
saveAscii:
    mov     eax, x_n              ; get x_n memory pos in eax
    mov     [eax], ecx            ; store result (ebx) in memory pos eax

    ret
    
    
; ------
; multiply()
; Multiplies two fixed point arithmetic numbers on op1 and op2
multiply:
    push    eax                   ; store eax
    push    ebx                   ; store ebx
    
    ; clear registers
    mov     eax, 0                ; clear eax
    mov     ebx, 0                ; clear ebx
    
    ; flag isNegRes should start on 0
    mov     [isNegRes], al       ; move a 0 to isNegRes
    
    ; checks MSB of op1 and op2 to know if number is negative
    mov     eax, [op1]            ; load first operand on eax
    mov     ebx, eax              ; load copy of first operand on ebx
    mov     ecx, 16               ; load counter on ecx (16 bit numbers)
    call    checkNeg              ; checks if op1 is negative
    mov     [op1], eax            ; store eax result on op1 memory pos
    
    mov     eax, [op2]            ; load second operand on eax
    mov     ebx, eax              ; load copy of second operand on ebx
    mov     ecx, 16               ; load counter on ecx (16 bit numbers)
    call    checkNeg              ; checks if op2 is negative
    mov     [op2], eax            ; store eax result on op2 memory pos
    
    ; calculate result of multiplication with algorithm for fixed point arithmetic    
    call    calculateFPAMulti     ; calculates multiplication result according to low, mid and high
    
    ; check if result of operation is negative to change result sign
    mov     eax, [resultMulti]    ; store multiplication result in eax
    call    checkResultNeg        ; call to check if value in eax should be negative
    mov     dword[resultMulti], eax ; move updated result to same memory pos
    
    mov     byte[isNegRes], 0     ; restore is neg res value to 0 
    
    pop     ebx                   ; restore ebx
    pop     eax                   ; restore eax
        
    ret    
        
        
; ------
; checkNeg()
; Checks if operand on eax is negative (fixed point arithmetic)
checkNeg:
    ; cut down number to get msb 15 times, this will determine if if is negative
    push    ebx                   ; save copy of operand
    mov     ebx, 2                ; denominator of division
    mov     edx, 0                ; clear edx to avoid mult problems
    div     ebx                   ; divide eax (operand) by ebx (2)
    pop     ebx,                  ; restore copy of operand
    
    sub     ecx, 1                ; counter--
    cmp     ecx, 1                ; check if msb is reached
    jz      checkMSB              ; continue loop
    
    jmp     checkNeg              ; check msb to know if number is negative
    
checkMSB:
    cmp     eax, 1                ; compare result (msb) to 1 to know if it should be applied 2s complement
    jz      revertTC              ; if number is negative, revert two's complement
    jnz     returnMSB
    
returnMSB:
    mov     eax, ebx              ; restore copy of operand (ebx) on eax                          
    ret  
    
    
; ------
; revertTC()
; Reverts two's complement of operand in eax
revertTC:
    mov     eax, ebx              ; restore copy of operand (ebx) on eax
    
    ; revert two's complement
    xor     eax, 0xffff           ; apply xor of operand with 1111 1111 1111 1111 to exchange 0-1 and 1-0
    add     eax, 1                ; add 1 (two's complement)
    
    ; change flag to know if result should be negative
    ; flag isNegRes starts on 0. First time this is reached, it flips to 1. Second time if flips back to 0. (XOR)
    ; thus, if by the end the flag is 0, result isn't negative, else it is
    mov     ebx, [isNegRes]       ; move isNegRes flag to ebx
    xor     ebx, 1                ; xor with 1 to flip bit
    mov     byte[isNegRes], bl    ; store byte of isNegRes on its position in memory
    
    ret
    
    
; ------
; readFirstLine()
; Opens and reads first line of in txt file
readFirstLine:
    ; open file
    mov     ecx, 0                ; ecx on 0 for file on read mode
    mov     ebx, inAudioFile      ; ebx on file name
    mov     eax, 5                ; kernel code for sys_open file
    int     80h                   ; os execute
    
    ; store input file descriptor
    mov     [inDescr], eax        ; store input file descriptor
    
    ; seek place in file
    mov     edx, 0                ; seek end 0 - start from beggining
    mov     ecx, 0                ; move the cursor 0 bytes
    mov     ebx, [inDescr]        ; move file descriptor to ebx
    mov     eax, 19               ; kernel opcode 19 for sys_lseek
    int     80h                   ; os execute
    
    ; read file contents
    mov     edx, 7                ; amount of bytes read on edx
    mov     ecx, lineIn           ; store input line on ecx
    mov     ebx, [inDescr]        ; store descriptor in ebx
    mov     eax, 3                ; kernel op code 3 sys_read
    int     80h                   ; os execute
    
    ret
    
    
; ------
; readNextLine()
; Reads the next line of in txt from cursor
readNextLine:
    ; move cursor to next line
    mov     edx, 1                ; seek end 1 - start where it left
    mov     ecx, 0                ; move cursor by offset 2 bytes
    mov     ebx, [inDescr]        ; file descriptor
    mov     eax, 19               ; kernel op code 19 for sys_lseek
    int     80h                   ; os execute
    
    ; read next bytes from file
    mov     edx, 7                ; read 7 bytes
    mov     ecx, lineIn           ; move memory address of file to ecx
    mov     ebx, [inDescr]        ; file descriptor
    mov     eax, 3                ; kernel op code 3 sys_read
    int     80h                   ; os execute
    
    ret


; ------
; rwAll()
; Read-write loop 
rwAll:
    ; first line is sample rate, which is useless in assembly
    call    readFirstLine         ; read first line subroutine
    call    writeFirstLine        ; write first line subroutine
    
    ; get k value
    call    readNextLine          ; read second line (k value)
    call    loadInput             ; convert k ascii to num and store in x_n
    push    eax                   ; store eax
    mov     eax, [x_n]            ; move k num in eax
    mov     [k], eax              ; save k (eax) in k position
    pop     eax                   ; restore eax
    call    writeNextLine         ; write k back to txt
    
    ; get alpha value
    call    readNextLine          ; read third line (alpha value)
    call    loadInput             ; convert alpha ascii to num and store in x_n
    push    eax                   ; store eax
    mov     eax, [x_n]            ; move alpha num in eax
    mov     [alpha], eax          ; save alpha (eax) in alpha position
    pop     eax                   ; restore eax
    call    writeNextLine         ; write alpha back to txt
    
rwLoop:
    call    readNextLine          ; read next line
    
    ; load current line
    mov     edx, lineIn           ; move current line pos to edx
    mov     eax, 0                ; set eax on 0
    mov     al, byte[edx]         ; move in al (eax) a byte in pos edx (line in start)
    
    cmp     eax, 70               ; compare eax to 70 ASCII letter F to detect FINAL keyword
    jz      returnRW              ; return
    
    call    loadInput             ; convert ascii line in to decimal number
    call    applyOperation        ; apply operation to x_n and stores it in y_n
    call    unloadOutput          ; convert output y_n to ascii and stores it in lineIn to be written
    
    call    writeNextLine         ; write next line
    
    jmp     rwLoop                ; continue loop
    
returnRW:
    call    writeNextLine         ; write last line FINAL

    ret
    
    
; ------
; unloadOutput()
; unloads output y_n to ascii character on lineIn
unloadOutput:
    ; copy y_n to y_n_temp to be cut for analysis
    push    eax                   ; save eax
    mov     eax, [y_n]            ; save y_n contents on eax
    mov     [y_n_temp], eax       ; copy y_n (eax) on y_n_temp
    pop     eax                   ; restore eax
    
    mov     ebx, lineIn           ; save lineIn memory pos on ebx
    add     ebx, 4                ; add 4 to ebx to move memory pos to last digit
    
    mov     ecx, 0                ; init ecx counter on 0 to determine end of ascii character writing

unloadOutputAux:
    push    eax                   ; save eax
    push    edx                   ; save edx
    push    ebx                   ; save ebx (memory pos to write)
    
    ; get last digit (num % 10)
    mov     eax, [y_n_temp]       ; load y_n_temp copy to eax
    mov     ebx, 10               ; load ebx denominator with 10
    mov     edx, 0                ; move 0 to edx to avoid division errors
    div     ebx                   ; divide eax (number) by ebx (10)
    add     edx, 48               ; add 48 to remainder of div (last digit) to get ascii code
    
    pop     ebx                   ; restore ebx (memory pos to write)
    mov     [ebx], dl             ; store dl (8 bit ascii character) on memory pos ebx (to write)
    
    mov     [y_n_temp], eax       ; move eax (div quotient - number without last digit) on y_n_temp pos
   
    inc     ecx                   ; counter + 1
    sub     ebx, 1                ; substract 1 to ebx memory pos to write to go backwards
    
    pop     edx                   ; restore edx
    pop     eax                   ; restore eax
    
    cmp     ecx, 5                ; compare counter to 4 (from 0 to 4, 5 ascii characters)
    jnz     unloadOutputAux       ; continue loop

    ret

    
; ------
; writeFirstLine()
; Opens and writes the first line of out txt file
writeFirstLine:
    ; create file
    mov     ecx, 0777o            ; set permissions to read, write and execute
    mov     ebx, outAudioFile     ; file name to create
    mov     eax, 8                ; kernel opcode 8 sys_create
    int     80h                   ; os execute
    
    ; store audio 
    mov     [outDescr], eax       ; store output file descriptor

    ; write line on file
    mov     edx, 7                ; write 7 bytes to new txt file
    mov     ecx, lineIn           ; write contents of line in to new file
    mov     ebx, [outDescr]       ; move file descriptor of out file to ebx
    mov     eax, 4                ; kernel op code 4 to sys_write
    int     80h                   ; os execute
   
    ret
    
    
; ------
; writeNextLine()
; Writes the next line of new out txt from cursor
writeNextLine:
    ; move cursor to next line
    mov     edx, 1                ; seek end 1 - start where it left
    mov     ecx, 0                ; move cursor 0 bytes
    mov     ebx, [outDescr]       ; file descriptor
    mov     eax, 19               ; kernel op code 19 for sys_lseek
    int     80h                   ; os execute 

    ; write next bytes from file
    mov     edx, 7                ; write 7 bytes
    mov     ecx, lineIn           ; move memory address of file to ecx
    mov     ebx, [outDescr]       ; file descriptor
    mov     eax, 4                ; kernel op code 3 sys_write
    int     80h                   ; os execute
    
    ret
   