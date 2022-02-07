function df = table2dataframe(t)
arguments
    t table {mustBeNonempty}
end

t           = splitvars(t);
varNames    = t.Properties.VariableNames;
varClasses  = varfun(@class, t);
varClasses  = string(table2cell(varClasses));
varClasses  = unique(varClasses, "stable");
df          = py.pandas.DataFrame();

for i = 1 : numel(varClasses)
    varClass    = varClasses(i);
    subt        = t(:, vartype(varClass));
    subNames    = subt.Properties.VariableNames;
    
    switch varClass
 
        case "struct"
            % TODO
            x               = subt{:, subNames};
            index           = ismember(varNames, subNames);
            varNames(index) = [];
            subNames        = fieldnames(x);
            subNames        = subNames(:).';
            varNames        = [varNames subNames]; %#ok<AGROW> 
            
        otherwise
            x = subt{:, subNames};

    end

    x = matlab.python.matlab2py(x);

    switch varClass
        case "categorical"
            x.columns = subNames;
        case "datetime"
            x.columns = subNames;
        case "logical"
            x = py.pandas.DataFrame(py.numpy.array(x), columns = subNames);
        otherwise
            x = py.pandas.DataFrame(x, columns = subNames);

    end

    df  = py.pandas.concat({df, x}, axis = 1);

end

df = df.reindex(columns=varNames);

end