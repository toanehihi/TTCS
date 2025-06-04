-- Manager toàn quyền
GRANT ALL PRIVILEGES ON labscheduler.* TO 'MANAGER';

--LECTURER
-- Quyền xem dữ liệu, gửi báo cáo, đổi mật khẩu
GRANT SELECT ON labscheduler.* TO 'LECTURER';

-- Cho phép thêm báo cáo
GRANT INSERT ON labscheduler.report TO 'LECTURER';

-- Cho phép đổi mật khẩu
GRANT EXECUTE ON PROCEDURE labscheduler.ChangePassword TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.Login TO 'LECTURER';

-- Cho phép xem lịch, lớp, học phần
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllSchedule TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetScheduleById TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllClass TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllCourse TO 'LECTURER';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllSubject TO 'LECTURER';

-- Cho phép gửi báo cáo
GRANT EXECUTE ON PROCEDURE labscheduler.InsertReport TO 'LECTURER';


--STUDENT
-- Quyền xem dữ liệu cá nhân, lịch, lớp, học phần
GRANT SELECT ON labscheduler.student_account TO 'STUDENT';
GRANT SELECT ON labscheduler.schedule TO 'STUDENT';
GRANT SELECT ON labscheduler.class TO 'STUDENT';
GRANT SELECT ON labscheduler.course TO 'STUDENT';
GRANT SELECT ON labscheduler.subject TO 'STUDENT';

-- Cho phép đăng nhập, đổi mật khẩu
GRANT EXECUTE ON PROCEDURE labscheduler.Login TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.ChangePassword TO 'STUDENT';

-- Cho phép xem lịch học, lớp, học phần
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllSchedule TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.GetScheduleById TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllClass TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllCourse TO 'STUDENT';
GRANT EXECUTE ON PROCEDURE labscheduler.GetAllSubject TO 'STUDENT';