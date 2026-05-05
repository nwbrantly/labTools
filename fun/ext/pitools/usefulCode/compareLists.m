function [bool,idxs] = compareLists(list1,list2)
%Searches for strings in list2 to match any string in list1.
%List2 has to be a cell array of strings.
%List 1 has to be a cell array containing strings or cell arrays of
%strings, to allow for multiple alternative spellings.
%bool & idxs are of the same size as list2
%bool(i) is true if list2{i} is found in list1
%idxs(i), if bool(i)==true, contains the element of list1 that contains the string list2{i} such that
%any(strcmp(list2{i},list1{idxs(i)}))=true. Note that since list1{idxs(i)}
%may contain a cell array of strings, strcmp(list2{i},list1{idxs(i)}) may
%return a boolean vector
warning('Deprecated: use compareListsNested')
[bool,idxs] = compareListsNested(list1,list2);
end

