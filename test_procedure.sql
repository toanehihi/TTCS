CALL InsertManagerAccount('sieu1','sieu1','sieu1@gmail.com','032312322','1999-01-01',1);

CALL InsertLecturerAccount('sieu1338','sieu1','sieu1@gmail.com','0331535722',1, '1999-01-01', 1);

CALL InsertStudentAccount('sieu1123','sieu1123','0239715622','sieu1123@gmail.com',1, '1999-01-01', 1);

CALL InsertSemester('2026-1','Học kì 1 2025-2026','2025-08-04','2025-12-31','1');

CALL InsertSchedule(1,1,2,2,84,1,4,61,'PRACTICE');

CALL GetAllStudentsByClassId(2);

CALL GetAllStudentsByCourseSection(2);

CALL GetAllStudentsByCourseId(1);

CALL GetLecturerReports(83);

CALl GetAllReports();

CALL GetAllSchedulesByCourseId(1);