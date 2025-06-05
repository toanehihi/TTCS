CREATE ROLE 'MANAGER';
CREATE ROLE 'LECTURER';
CREATE ROLE 'STUDENT';

-- Manager toàn quyền
GRANT ALL PRIVILEGES ON labscheduler.* TO 'MANAGER';

-- Phân quyền cho role LECTURER
-- Quyền xem dữ liệu trên các bảng liên quan
GRANT SELECT ON labscheduler.student_account TO 'LECTURER';
GRANT SELECT ON labscheduler.schedule TO 'LECTURER';
GRANT SELECT ON labscheduler.class TO 'LECTURER';
GRANT SELECT ON labscheduler.course TO 'LECTURER';
GRANT SELECT ON labscheduler.subject TO 'LECTURER';
GRANT SELECT ON labscheduler.course_section TO 'LECTURER';
GRANT SELECT ON labscheduler.semester TO 'LECTURER';
GRANT SELECT ON labscheduler.semester_week TO 'LECTURER';
GRANT SELECT ON labscheduler.department TO 'LECTURER';
GRANT SELECT ON labscheduler.report TO 'LECTURER';
GRANT SELECT ON labscheduler.report_log TO 'LECTURER';

-- Quyền thêm báo cáo
GRANT INSERT ON labscheduler.report TO 'LECTURER';

-- Gán quyền thực thi stored procedure cho LECTURER
GRANT EXECUTE ON PROCEDURE labscheduler.getAllStudentsByClassId TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllStudentsByCourseSection TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.getAllStudentsByCourseId TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetLecturerReports TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.InsertReport TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.getLecturersByCourseId TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.ChangePassword TO 'LECTURER';

--STUDENT
GRANT SELECT ON labscheduler.student_account TO 'STUDENT';
GRANT SELECT ON labscheduler.schedule TO 'STUDENT';
GRANT SELECT ON labscheduler.class TO 'STUDENT';
GRANT SELECT ON labscheduler.course TO 'STUDENT';
GRANT SELECT ON labscheduler.subject TO 'STUDENT';
GRANT SELECT ON labscheduler.course_section TO 'STUDENT';
GRANT SELECT ON labscheduler.semester TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.ChangePassword TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllScheduleByCourseId TO 'STUDENT';
