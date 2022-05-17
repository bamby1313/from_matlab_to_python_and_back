%% matlab2py

%%
function pythonData = matlab2py(matlabData)
% import pandas module
isPandas = pyrun(["import sys", "bool = 'pandas' in sys.modules"], "bool");
isNumpy  = pyrun(["import sys", "bool = 'numpy' in sys.modules"], "bool");
if ~isPandas
    pyrun("import pandas");
end
if ~isNumpy
    pyrun("import numpy");
end

% convert MATLAB into Python
pythonData = recursiveFunMatlab2Py(matlabData);

switch string(class(matlabData))
    case "categorical"
        pythonData = py.pandas.DataFrame(pythonData);
        pythonData = pythonData.astype('category');
    case "datetime"
        pythonData = py.pandas.DataFrame(py.pandas.to_datetime(pythonData));
    otherwise    
%         pythonData = 
end

%% matlabConversion²
    function pyData = matlabConversion(matlabData)
        if isempty(matlabData)
            matlabData = '';
        end
        
        matlabType = class(matlabData);
        switch matlabType
            case 'char'
                if isrow(matlabType)
                    pyData = py.str(matlabData(:).');
                elseif iscolumn(matlabData)
                    pyData = py.str(matlabData(:));
                end
            
            case 'string'
                temp    = convertStringsToChars(matlabData); 
                pyData  = py.str(temp(:).');

            case {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
                if islogical(matlabData)
                    matlabData = double(matlabData);
                end
                mysize = size(matlabData);
                
                if numel(mysize) > 2
                    % More than 2 dimensions can be translated by nestings
                    % lists. I'm sure this can be done using a recursive
                    % function; Add it to the feature wishlist.
                    error('crmat2py:tooManyDimNum','A matrix of numbers was found to have more than 2-dimensions, which this function cannot translate into Python.');
                
                elseif all(mysize > 1)
                    % a two dimensional matrix
                    matlabData2 = num2cell(matlabData,2);
                    matlabData3 = cellfun(@py.list,matlabData2,'UniformOutput',false);
                    pyData      = py.list(transpose(matlabData3));
                
                elseif any(mysize > 1)
                    % an array of numbers
                    if isrow(matlabData)
                        pyData = py.list(matlabData(:).');
                    elseif iscolumn(matlabData)
                        pyData = py.list(matlabData(:));
                    end
                else
                    % a number
                    pyData = py.float(matlabData);
                end
            
            case 'logical'
                mysize = size(matlabData);
                if numel(mysize) > 2
                    % More than 2 dimensions can be translated by nestings
                    % lists. I'm sure this can be done using a recursive
                    % function; Add it to the feature wishlist.
                    error('crmat2py:tooManyDimNum','A matrix of numbers was found to have more than 2-dimensions, which this function cannot translate into Python.');
                elseif all(mysize > 1) || any(mysize > 1)
                    % an array of logical
                    pyData = py.memoryview(matlabData);
                else
                    % a logical scalar
                    pyData = py.bool(matlabData);
                end
                
            case 'cell'
                mysize = size(matlabData);
                
                if numel(mysize) > 2
                    % More than 2 dimensions can be translated by nestings
                    % lists. I'm sure this can be done using a recursive
                    % function; Add it to the feature wishlist.
                    error('crmat2py:tooManyDimCell','A cell was found to have more than 2-dimensions, which this function cannot translate into Python.');
                
                elseif all(mysize > 1)
                    % a two dimensional cell
                    matlabData2 = num2cell(matlabData,2); %Surprisingly useful when the input is a cell.
                    matlabData3 = cellfun(@py.list,matlabData2,'UniformOutput',false);
                    pyData      = py.list(transpose(matlabData3));
                
                elseif any(mysize > 1)
                    % a 1D cell
                    % Only 1xN vector supported in Python
                    pyData = py.list(matlabData(:).');
                else
                    % a 1x1 cell
                    pyData = py.list(matlabData);
                end
            
            case 'struct'
                mysize = size(matlabData);
                
                if numel(mysize) > 2
                    % More than 2 dimensions can be translated by nestings
                    % lists. I'm sure this can be done using a recursive
                    % function; Add it to the feature wishlist.
                    error('crmat2py:tooManyDimStruct','A struct was found to have more than 2-dimensions, which this function cannot translate into Python.');
                
                elseif all(mysize > 1)
                    % a two dimensional struct
                    matlabData2 = num2cell(matlabData,2); %Surprisingly useful when the input is a struct, too.
                    for i = 1:numel(matlabData2)
                        matlabData2{i} = num2cell(matlabData2{i},1);
                        matlabData2{i} = cellfun(@py.dict,matlabData2{i},'UniformOutput',false);
                    end
                    matlabData3 = cellfun(@py.list,matlabData2,'UniformOutput',false);
                    pyData      = py.list(transpose(matlabData3));
                
                elseif any(mysize > 1)
                    % a 1D struct
                    matlabData  = num2cell(matlabData(:).',1);
                    matlabData  = cellfun(@py.dict,matlabData,'UniformOutput',false);
                    pyData      = py.list(matlabData);
                
                else
                    % a 1x1 struct
                    pyData = py.dict(matlabData);
                end
            
            case 'missing'
                mysize = size(matlabData);
                if all(mysize > 1) || any(mysize > 1)
                    dimstr  = "((" + join(string(mysize), ",") + "))";
                    pyData  = pyrun("import numpy; pyData = numpy.empty" + dimstr, "pyData"); %#ok<NASGU> 
                    pyData  = pyrun("pyData[:] = numpy.nan", "pyData");
                else
                    % a 1x1 struct
%                     pyData = py.dict(matlabData);
                end

            case 'table'
                pyData  = matlab.python.table2dataframe(matlabData);
            
            case 'timetable'
                pyData  = matlab.python.timetable2dataframe(matlabData);

            case 'datetime'
                error("Datetime not supported. Must be converted in py.str variable type.")

            case 'categorical'
                error("Categorical not supported. Must be converted in py.str variable type.")

            otherwise
                pyData  = matlabData;
        end
    end

%% recursiveFunMatlab2Py
% Loops through the data structure turning MATLAB data types into Python
% data types
    function pyData = recursiveFunMatlab2Py(matlabData)
        matlabType  = class(matlabData);
        mynum       = numel(matlabData);
        switch matlabType
            case 'cell'
                for i = 1:mynum
                    matlabData{i} = recursiveFunMatlab2Py(matlabData{i});
                end
            
            case 'struct'
                for i = 1:mynum
                    myfields = fieldnames(matlabData(i));
                    for j = 1:numel(myfields)
                        matlabData(i).(myfields{j}) = recursiveFunMatlab2Py(matlabData(i).(myfields{j}));
                    end
                end
            
            case 'string'
                matlabData = recursiveFunMatlab2Py(convertStringsToChars(matlabData));

            case {'categorical', 'datetime'}
                matlabData = recursiveFunMatlab2Py(convertStringsToChars(string(matlabData)));

        end
        pyData = matlabConversion(matlabData);
    end
end
