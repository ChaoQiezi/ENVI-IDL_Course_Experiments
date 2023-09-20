; @Author: ChaoQiezi
; @Email: chaoqiezi.one@qq.com
; @Time: 2023-09-11

; This script is used to basic practice

; This function is used to print array
function  printArray, arr, prefix=prefix, format=format
    dims = size(arr, /dimensions)
    if  n_elements(prefix) then print, prefix
    if ~n_elements(format) then format='%.2f'
    
    for row = 0, dims[1] - 1 do begin
        arr_row = arr[*, row]
        formatted_row = strcompress(string(arr_row, format=format))
        
        output = '      '
        for col = 0, dims[0] - 1 do begin
            output += formatted_row[col]
            if col ne dims[0] - 1 then output += ', '
        endfor
        
        print, output
    endfor
end

pro basic_pracitce
    ; question-1
    a = findgen(4, 6)  ; define the index array(float)
    b = 3s  ; define the int var
    c = [3]  ; define the array
    d = [9, 3, 1]
    print, 'the value for col 3 and row 4 is: ' + string(a[3, 4], format='%.2f')
    print, 'the value with index 15: ' + string(a[15], format='%.2f')
    printArray, a + b, PREFIX='a plus b is equal to: '
    print, 'a[1, 1] plus b is equal to: ' + string(a[1, 1] + b, format='%.2f')
    print, 'a plus b is equal to: ', a + c & help, a + c
    print, 'a plus c is equal to: ', a + d & help, a + d
    
    ; question2
    a = [[3, 9, 10], [2, 7, 5], [4, 1, 6]]
    b = [[7, 10, 2], [5, 8, 9], [3, 1, 6]]
    printArray, a + b, prefix='a plus b is equal: ' 
    printArray, a * b, prefix='a times b is equal to: '
    
    ; question3
    a = [[0, 5, 3], [4, 0, 2], [0, 7, 8]]
    b = [[0, 0, 1], [9, 7, 4], [1, 0, 2]]
    printArray, (a gt 3) * a, prefix='keep the result greater than 3 in a, and set all the rest to 0: '
    printArray, (b le 4) * b + (b gt 4) * 9, prefix='keep the result less than or equal to 3 in ' + $
        'a, and set all the rest to 9: ', format='%i'
    printArray, (a + b) / 2.0, prefix='calculate the mean of a and b: '
    printArray, ((a ne 0) and (b ne 0)) * ((a + b) / 2.0)+ (a eq 0) * b + (b eq 0) * a, $
        prefix='calculate the mean of a and b, and 0 values are not included in the calculation: '
    print, (a + b) / float((a ne 0) + (b ne 0))  ; equal above and simple    
    
    ; question4
    img = findgen(1024, 1024)
;    image(img, /order)
    write_tiff, 'D:\Objects\JuniorFallTerm\IDLProgram\Project\ExperimentsMe\Week1\Data\temp.tiff', img
end