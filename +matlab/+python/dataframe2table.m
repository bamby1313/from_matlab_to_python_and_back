function t = dataframe2table(df)
arguments
    df (1,1) {mustBeADataFrame, mustBeNonempty}
end

import matlab.python.*

varNames = string(df.columns.tolist());

df_numerical    = df.select_dtypes(include = 'number');
df_categorical  = df.select_dtypes(include = 'category');
df_string       = df.select_dtypes(include = 'object');
df_logical      = df.select_dtypes(include = 'bool');
df_datetime     = df.select_dtypes(include = 'datetime');

t = table();

% numeric
if ~df_numerical.empty
    columnNames = df_numerical.columns.tolist();
    matlabData  = double(df_numerical.to_numpy);
    t           = [t array2table(matlabData, "VariableNames", string(columnNames))];
end

% categorical
if ~df_categorical.empty
    columnNames = df_categorical.columns.tolist();
    matlabData  = py2matlab(df_categorical.values.T.tolist());
    matlabData  = cellfun(@(x) categorical(string(x')), matlabData, "un", 0);
    t           = [t array2table([matlabData{:}], "VariableNames", string(columnNames))];
end

% string
if ~df_string.empty
    columnNames = df_string.columns.tolist();
    matlabData  = py2matlab(df_string.values.T.tolist());
    matlabData  = cellfun(@(x) string(x'), matlabData, "un", 0);
    t           = [t array2table([matlabData{:}], "VariableNames", string(columnNames))];
end

% boolean
if ~df_logical.empty
    columnNames = df_logical.columns.tolist();
    matlabData  = logical(df_logical.values);
    t           = [t array2table(matlabData, "VariableNames", string(columnNames))];
end

% datetime
if ~df_datetime.empty
    columnNames = df_datetime.columns.tolist();
    matlabDates = py2matlab(df_datetime.values.tolist);
    matlabDates = string(matlabDates);
    matlabData  = datetime(matlabDates(:),'InputFormat','yyyy-MM-dd');
    t           = [t array2table(matlabData, "VariableNames", string(columnNames))];
end

% index
if ~df.index.empty
    pyIndex = df.index;
    if isa(pyIndex, "py.pandas.core.indexes.datetimes.DatetimeIndex") 
        columnNames = string(df.index.name);
        if isempty(string(columnNames))
            columnNames = "TIME";
        end   
        varNames    = [columnNames varNames];
        dt          = df.index.strftime('%Y-%m-%d %r');
        matlabDates = py2matlab(dt.values.tolist);
        matlabDates = string(matlabDates);
        matlabData  = datetime(matlabDates(:));
        t           = [t array2table(matlabData, "VariableNames", columnNames)];
    end
end

t = t(:, varNames);

end

function mustBeADataFrame(df)
    c = class(df);
    if ~(c == "py.pandas.core.frame.DataFrame")
        eid = 'Class:notADataFrame';
        msg = 'Input data must be a DataFrame.';
        throwAsCaller(MException(eid,msg))
    end
end