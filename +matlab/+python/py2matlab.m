%% Core_py2matlab
function matlabData = py2matlab(pythonData)

python.prop = vertcat(properties(pythonData));

if isempty(python.prop)
    matlabData = recursiveFunPy2Matlab(pythonData);
else
    for p = 1 : numel(python.prop)

        pData = pythonData.(python.prop{p});
        % convert Python into MATLAB
        matlabData.(python.prop{p}) = recursiveFunPy2Matlab(pData);
        %%%
        % Matrices of numbers are converted into cells, so another function will
        % reformat these into matrices.
        matlabData.(python.prop{p}) = recursiveFunCell2MatCheck(matlabData.(python.prop{p}));

    end
end

end

%% pythonConversion
function matlabData = pythonConversion(pyData)
pyType = class(pyData);
switch pyType
    case {'py.str','py.unicode'}
        matlabData = string(pyData);
    case 'py.bytes'
        matlabData = uint8(pyData);
    case {'py.int','py.long','py.array.array'}
        matlabData = double(pyData);
    case {'py.list','py.tuple'}
        if pyData.string == "None"
            matlabData = nan;
        else
            matlabData = cell(pyData);
        end
    case 'py.dict'
        matlabData = struct(pyData);
    case 'py.numpy.ndarray'
        matlabData = pyData.T.tolist();
        matlabData = pythonConversion(matlabData);
    otherwise
        matlabData = pyData;
end
end

%% recursiveFunPy2Matlab
% Loops through the Python data types and converts them into MATLAB data
% types
function matlabData = recursiveFunPy2Matlab(pyData)
matlabData  = pythonConversion(pyData);
matlabType  = class(matlabData);
mynum       = numel(matlabData);
switch matlabType
    case 'cell'
        for i = 1:mynum
            matlabData{i} = recursiveFunPy2Matlab(matlabData{i});
        end
    case 'struct'
        for i = 1:mynum
            myfields = fieldnames(matlabData(i));
            for j = 1:numel(myfields)
                matlabData(i).(myfields{j}) = recursiveFunPy2Matlab(matlabData(i).(myfields{j}));
            end
        end
end
end

%% recursiveFunCell2MatCheck
% A second loop through the data structure identifies numeric matrices
% stored as cells
function mydata = recursiveFunCell2MatCheck(mydata)
myType = class(mydata);
mynum = numel(mydata);
switch myType
    case 'cell'
        if iscellstr(mydata)
            return
        elseif all(cellfun(@isnumeric,mydata(:)))
            % This is the key condition. A cell full of numbers
            % will be converted into a matrix.
            try
                mydata = cell2mat(mydata);
            catch
                %do nothing
            end
        else
            for i = 1:mynum
                mydata{i} = recursiveFunCell2MatCheck(mydata{i});
            end
            if all(cellfun(@isnumeric,mydata(:)))
                % This is to handle 2D matrices. Anything that has
                % more than 2 dimensions will be flattened to 2D.
                try
                    mydata = cell2mat(transpose(mydata));
                catch
                    %do nothing
                end
            end
        end
    case 'struct'
        for i = 1:numel(mydata)
            myfields = fieldnames(mydata(i));
            for j = 1:numel(myfields)
                mydata(i).(myfields{j}) = recursiveFunCell2MatCheck(mydata(i).(myfields{j}));
            end
        end
end
end

