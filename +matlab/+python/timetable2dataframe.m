function df = timetable2dataframe(t)
arguments
    t timetable {mustBeNonempty}
end
import matlab.python.*

t   = timetable2table(t);
df  = table2dataframe(t);
df  = df.set_index(t.Properties.VariableNames{1});

end