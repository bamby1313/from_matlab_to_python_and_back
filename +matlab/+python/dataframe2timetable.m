function tt = dataframe2timetable(df)
arguments
    df (1,1) {mustBeADataFrame, mustBeNonempty}
end
import matlab.python.*

t  = dataframe2table(df);
tt = table2timetable(t);

end

function mustBeADataFrame(df)
    c = class(df);
    if ~(c == "py.pandas.core.frame.DataFrame")
        eid = 'Class:notADataFrame';
        msg = 'Input data must be a DataFrame.';
        throwAsCaller(MException(eid,msg))
    end
end