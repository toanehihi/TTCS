DELIMITER //

CREATE PROCEDURE `InsertManagerAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(10),
    IN p_birthday DATE,
    IN p_gender BIT
)
BEGIN
    DECLARE new_account_id BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Kiểm tra trùng mã quản lý
    IF EXISTS (SELECT 1 FROM manager_account WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã quản lý đã tồn tại!';
    END IF;

    -- Check trùng email ở 3 bảng người dùng
    IF EXISTS (
        SELECT 1 FROM manager_account WHERE email = p_email
        UNION
        SELECT 1 FROM student_account WHERE email = p_email
        UNION
        SELECT 1 FROM lecturer_account WHERE email = p_email
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email đã được sử dụng!';
    END IF;

    -- Check trùng phone 3 bảng người dùng
    IF EXISTS (
        SELECT 1 FROM manager_account WHERE phone = p_phone
        UNION
        SELECT 1 FROM student_account WHERE phone = p_phone
        UNION
        SELECT 1 FROM lecturer_account WHERE phone = p_phone
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Số điện thoại đã được sử dụng!';
    END IF;

    -- Kiểm tra username exist?
    IF EXISTS (SELECT 1 FROM account WHERE username = p_code) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên tài khoản đã tồn tại!';
    END IF;

    -- Thêm vào bảng account
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (p_code, SHA2(p_code, 256), 1, 'ACTIVE', CURRENT_TIMESTAMP);

    SET new_account_id = LAST_INSERT_ID();

    -- Thêm vào bảng manager_account
    INSERT INTO manager_account (account_id, code, full_name, email, phone, birthday, gender)
    VALUES (new_account_id, p_code, p_full_name, p_email, p_phone, p_birthday, p_gender);

    -- Tạo user MySQL
    SET @sql = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', p_code, '\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Phân quyền
    SET @sql_grant = CONCAT('GRANT MANAGER TO \'', p_code, '\'@\'localhost\';');
    PREPARE stmt_grant FROM @sql_grant;
    EXECUTE stmt_grant;
    DEALLOCATE PREPARE stmt_grant;

    COMMIT;
END;
//
DELIMITER ;

#========================================================================================================================================================================
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertLecturerAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(10),
    IN p_gender BIT,
    IN p_birthday DATE,
    IN p_department_id BIGINT
)
BEGIN
    DECLARE acc_id BIGINT;
    DECLARE user_exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Kiểm tra trùng mã giảng viên
    IF EXISTS (SELECT 1 FROM lecturer_account WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Mã giảng viên đã tồn tại!';
    END IF;

    -- Kiểm tra trùng email
    IF EXISTS (
        SELECT email FROM lecturer_account WHERE email = p_email
        UNION
        SELECT email FROM student_account WHERE email = p_email
        UNION
        SELECT email FROM manager_account WHERE email = p_email
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Email đã được sử dụng!';
    END IF;

    -- Kiểm tra trùng số điện thoại 
    IF EXISTS (
        SELECT phone FROM lecturer_account WHERE phone = p_phone
        UNION
        SELECT phone FROM student_account WHERE phone = p_phone
        UNION
        SELECT phone FROM manager_account WHERE phone = p_phone
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số điện thoại đã được sử dụng!';
    END IF;

    -- Kiểm tra username đã tồn tại trong bảng account
    IF EXISTS (SELECT 1 FROM account WHERE username = p_code) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tên tài khoản đã tồn tại!';
    END IF;

    -- Kiểm tra khoa có tồn tại
    IF NOT EXISTS (SELECT 1 FROM department WHERE id = p_department_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Khoa không tồn tại!';
    END IF;

    -- Thêm tài khoản vào bảng account
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (
        p_code,
        SHA2(p_code, 256),
        (SELECT id FROM role WHERE name = 'LECTURER'),
        'ACTIVE',
        CURRENT_TIMESTAMP
    );

    -- Lưu lại account_id
    SET acc_id = LAST_INSERT_ID();

    -- Thêm thông tin vào bảng lecturer_account
    INSERT INTO lecturer_account (
        account_id, code, full_name, email, phone, gender, birthday, department_id
    )
    VALUES (
        acc_id, p_code, p_full_name, p_email, p_phone, p_gender, p_birthday, p_department_id
    );

    -- Kiểm tra user MySQL đã tồn tại chưa
    SELECT COUNT(*) INTO user_exists
    FROM mysql.user
    WHERE user = p_code AND host = 'localhost';

    IF user_exists = 0 THEN
        -- Tạo user hệ thống MySQL
        SET @sql_create = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', p_code, '\';');
        PREPARE stmt FROM @sql_create;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Gán role hệ thống MySQL
    SET @sql_grant = CONCAT('GRANT `LECTURER` TO \'', p_code, '\'@\'localhost\';');
    PREPARE stmt_grant FROM @sql_grant;
    EXECUTE stmt_grant;
    DEALLOCATE PREPARE stmt_grant;

    COMMIT;
END$$

DELIMITER ;
#========================================================================================================================================================================
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertStudentAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_phone VARCHAR(10),
    IN p_email VARCHAR(255),
    IN p_gender BIT,
    IN p_birthday DATE,
    IN p_class_id BIGINT
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_account_id BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Kiểm tra mã sinh viên đã tồn tại 
    SELECT COUNT(*) INTO v_count FROM student_account WHERE code = p_code;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Mã sinh viên đã tồn tại.';
    END IF;

    -- Kiểm tra trùng email
    IF EXISTS (
        SELECT email FROM lecturer_account WHERE email = p_email
        UNION
        SELECT email FROM student_account WHERE email = p_email
        UNION
        SELECT email FROM manager_account WHERE email = p_email
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Email đã được sử dụng!';
    END IF;

    -- Kiểm tra trùng số điện thoại 
    IF EXISTS (
        SELECT phone FROM lecturer_account WHERE phone = p_phone
        UNION
        SELECT phone FROM student_account WHERE phone = p_phone
        UNION
        SELECT phone FROM manager_account WHERE phone = p_phone
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số điện thoại đã được sử dụng!';
    END IF;

    -- Kiểm tra username đã tồn tại trong bảng account
    SELECT COUNT(*) INTO v_count FROM account WHERE username = p_code;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tên tài khoản đã tồn tại.';
    END IF;

    -- Tạo tài khoản trong bảng account
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (
        p_code,
        SHA2(p_code, 256),
        (SELECT id FROM role WHERE name = 'STUDENT'),
        'ACTIVE',
        CURRENT_TIMESTAMP
    );

    -- Lấy account_id vừa tạo
    SET v_account_id = LAST_INSERT_ID();

    -- Thêm vào bảng student_account
    INSERT INTO student_account (account_id, code, full_name, phone, email, gender, birthday)
    VALUES (v_account_id, p_code, p_full_name, p_phone, p_email, p_gender, p_birthday);

    -- Thêm vào bảng student_on_class với trạng thái ENROLLED
    INSERT INTO student_on_class (student_id, class_id, type)
    VALUES (v_account_id, p_class_id, 'ENROLLED');

    -- Tạo user MySQL mới với mật khẩu là code
    SET @sql = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', p_code, '\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Gán role MySQL STUDENT
    SET @sql = CONCAT('GRANT STUDENT TO \'', p_code, '\'@\'localhost\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    COMMIT;
END$$

DELIMITER ;
#========================================================================================================================================================================
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertSemester`(
    IN p_code VARCHAR(36),
    IN p_name VARCHAR(36),
    IN p_start_date TIMESTAMP,
    IN p_end_date TIMESTAMP,
    IN p_start_week INT
)
BEGIN
    DECLARE v_semester_id INT;
    DECLARE v_week_start_date DATE;
    DECLARE v_week_end_date DATE;
    DECLARE v_week_number INT DEFAULT 0;

    IF EXISTS (SELECT 1 FROM semester WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã học kỳ đã tồn tại.';
    ELSEIF EXISTS (SELECT 1 FROM semester WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên học kỳ đã tồn tại.';
    ELSEIF p_start_date >= p_end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngày bắt đầu phải nhỏ hơn ngày kết thúc.';
    ELSEIF p_start_date >= p_end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngày bắt đầu và kết thúc không hợp lệ.';
    ELSE
        INSERT INTO semester(code, name, start_date, end_date)
        VALUES (p_code, p_name, p_start_date, p_end_date);

        SET v_semester_id = LAST_INSERT_ID();
        SET v_week_start_date = DATE(p_start_date);
        SET v_week_number = p_start_week;

        WHILE v_week_start_date <= DATE(p_end_date) DO
            SET v_week_end_date = DATE_ADD(v_week_start_date, INTERVAL 6 DAY);
            IF v_week_end_date > DATE(p_end_date) THEN
                SET v_week_end_date = DATE(p_end_date);
            END IF;

            INSERT INTO semester_week(name, start_date, end_date, semester_id)
            VALUES (
                CONCAT('Tuần ', v_week_number),
                v_week_start_date,
                v_week_end_date,
                v_semester_id
            );

            SET v_week_start_date = DATE_ADD(v_week_start_date, INTERVAL 7 DAY);
            SET v_week_number = v_week_number + 1;
        END WHILE;
    END IF;
END
#========================================================================================================================================================================
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertSchedule`(
    IN p_course_id BIGINT,
    IN p_course_section_id BIGINT,
    IN p_room_id BIGINT,
    IN p_day_of_week TINYINT,
    IN p_lecturer_id BIGINT,
    IN p_start_period INT,
    IN p_total_period INT,
    IN p_semester_week_id BIGINT,
    IN p_type ENUM('THEORY', 'PRACTICE')
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_start_date DATE;
    DECLARE v_target_date DATE;
    DECLARE v_message TEXT;

    -- Kiểm tra học phần tồn tại
    SELECT COUNT(*) INTO v_count FROM course WHERE id = p_course_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Học phần không tồn tại.';
    END IF;

    -- Kiểm tra tổ của học phần
    SELECT COUNT(*) INTO v_count FROM course_section WHERE id = p_course_section_id AND course_id = p_course_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tổ học phần không hợp lệ hoặc không thuộc môn học.';
    END IF;

    -- Kiểm tra phòng học tồn tại
    SELECT COUNT(*) INTO v_count FROM room WHERE id = p_room_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phòng học không tồn tại.';
    END IF;

    -- Kiểm tra phòng học có thể dùng cho học phần
    SELECT COUNT(*) INTO v_count FROM room WHERE id = p_room_id AND (
        (type = 'LECTURE_HALL' AND p_type = 'THEORY') OR
        (type = 'COMPUTER_LAB' AND p_type = 'PRACTICE')
    );
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phòng học không thể dùng cho học phần này.';
    END IF;

    -- Kiểm tra giảng viên tồn tại
    SELECT COUNT(*) INTO v_count FROM lecturer_account WHERE account_id = p_lecturer_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giảng viên không tồn tại.';
    END IF;

    -- Kiểm tra tuần học tồn tại
SELECT COUNT(*) INTO v_count FROM semester_week WHERE id = p_semester_week_id;
IF v_count = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Tuần học không tồn tại.';
END IF;

-- Lấy ngày bắt đầu tuần học
SELECT start_date INTO v_start_date FROM semester_week WHERE id = p_semester_week_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tuần học không tồn tại.';
    END IF;

    -- Tính ngày cụ thể theo thứ trong tuần
    SET v_target_date = DATE_ADD(v_start_date, INTERVAL p_day_of_week - 2 DAY); -- dayOfWeek 2-7 vì index của sql bắt đầu từ 0 nên phải -2

    -- Kiểm tra nếu ngày đã qua
    IF v_target_date <= CURRENT_DATE() THEN
        SET v_message = CONCAT('Không thể thêm lịch vì ngày ', DATE_FORMAT(v_target_date, '%d-%m-%Y'), ' đã qua.');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_message;
    END IF;

    -- Kiểm tra trùng lịch phòng học
    SELECT COUNT(*) INTO v_count
    FROM schedule
    WHERE semester_week_id = p_semester_week_id
      AND room_id = p_room_id
      AND day_of_week = p_day_of_week
      AND (
        p_start_period <= start_period + total_period - 1
        AND p_start_period + p_total_period - 1 >= start_period
      );
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phòng học đã được sử dụng vào thời gian này.';
    END IF;

    -- Kiểm tra trùng lịch giảng viên
    SELECT COUNT(*) INTO v_count
    FROM schedule
    WHERE lecturer_id = p_lecturer_id
      AND semester_week_id = p_semester_week_id
      AND day_of_week = p_day_of_week
      AND (
          (p_start_period BETWEEN start_period AND start_period + total_period - 1) OR
          (p_start_period + p_total_period - 1 BETWEEN start_period AND start_period + total_period - 1)
      );
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giảng viên đã có lịch vào thời gian này.';
    END IF;

    -- Thêm lịch mới với trạng thái mặc định 'IN_PROGRESS'
    INSERT INTO schedule (
        course_id, course_section_id, room_id, day_of_week,
        lecturer_id, start_period, total_period,
        semester_week_id, status, type
    )
    VALUES (
        p_course_id, p_course_section_id, p_room_id, p_day_of_week,
        p_lecturer_id, p_start_period, p_total_period,
        p_semester_week_id, 'IN_PROGRESS', p_type
    );
END
#========================================================================================================================================================================

CREATE PROCEDURE `GetAllStudentsByClassId`(
    IN p_class_id BIGINT
)
BEGIN
    SELECT
        s.account_id,
        s.code AS student_code,
        s.full_name,
        s.email,
        s.phone,
        s.gender,
        s.birthday,
        c.name AS class_name
    FROM student_account s
    JOIN student_on_class soc ON s.account_id = soc.student_id
    JOIN class c ON soc.class_id = c.id
    WHERE c.id = p_class_id;
END

#========================================================================================================================================================================
DELIMITER $$

CREATE PROCEDURE `GetAllStudentsByCourseId`(
    IN p_course_id BIGINT
)
BEGIN
    SELECT 
        s.account_id,
        s.code AS student_code,
        s.full_name,
        s.email,
        s.phone,
        s.gender,
        s.birthday,
        sub.name AS subject_name,
        cl.name AS class_name,
        sem.name AS semester_name,
        cs.section_number
    FROM student_account s
    JOIN student_on_course_section soc 
        ON s.account_id = soc.student_id
    JOIN course_section cs 
        ON soc.course_section_id = cs.id
    JOIN course c 
        ON cs.course_id = c.id
    JOIN class cl 
        ON c.class_id = cl.id
    JOIN subject sub 
        ON c.subject_id = sub.id
    JOIN semester sem 
        ON c.semester_id = sem.id
    WHERE c.id = p_course_id;
END $$

DELIMITER ;
#========================================================================================================================================================================
DELIMITER $$

CREATE PROCEDURE `GetAllStudentsByCourseSection`(
    IN p_course_section_id BIGINT
)
BEGIN
    SELECT 
        s.account_id,
        s.code AS student_code,
        s.full_name,
        s.email,
        s.phone,
        s.gender,
        s.birthday,
        sub.name AS subject_name,
        cl.name AS class_name,
        sem.name AS semester_name,
        cs.section_number
    FROM student_account s
    JOIN student_on_course_section soc ON s.account_id = soc.student_id
    JOIN course_section cs ON soc.course_section_id = cs.id
    JOIN course c ON cs.course_id = c.id
    JOIN class cl ON c.class_id = cl.id
    JOIN subject sub ON c.subject_id = sub.id
    JOIN semester sem ON c.semester_id = sem.id
    WHERE cs.id = p_course_section_id;
END$$

DELIMITER ;
#========================================================================================================================================================================
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertStudentOnCourse`(
    IN p_student_id BIGINT,
    IN p_course_id BIGINT
)
BEGIN
    -- Kiểm tra sinh viên có tồn tại
    IF NOT EXISTS (SELECT 1 FROM student_account WHERE id = p_student_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy sinh viên.';
    
    -- Kiểm tra môn học có tồn tại
    ELSEIF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy môn học.';
    
    -- Kiểm tra đã tồn tại bản ghi
    ELSEIF EXISTS (
        SELECT 1 FROM student_on_course 
        WHERE student_id = p_student_id AND course_id = p_course_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Sinh viên đã đăng ký môn học này.';
    
    ELSE
        -- Chèn bản ghi
        INSERT INTO student_on_course (student_id, course_id)
        VALUES (p_student_id, p_course_id);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetLecturerReports`(
    IN lecturer_id BIGINT
)
BEGIN
    SELECT
        a.account_id AS author_id,
        a.full_name,
        r.id AS report_id,
        r.title,
        r.content,
        rl.status,
        rl.created_at,
        rl.updated_at
    FROM report r
    JOIN lecturer_account a ON r.author_id = a.account_id
    JOIN report_log rl ON r.id = rl.report_id
    WHERE r.author_id = lecturer_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteStudentOnCourse`(
    IN p_student_id BIGINT,
    IN p_course_section_id BIGINT
)
BEGIN
    -- Kiểm tra sinh viên có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM student_account WHERE account_id = p_student_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên không tồn tại!';
    END IF;

    -- Kiểm tra course_section có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM course_section WHERE id = p_course_section_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lớp học phần không tồn tại!';
    END IF;

    -- Kiểm tra mối quan hệ có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM student_on_course 
        WHERE student_id = p_student_id AND course_section_id = p_course_section_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên không thuộc lớp học phần này!';
    END IF;

    -- Xóa bản ghi
    DELETE FROM student_on_course
    WHERE student_id = p_student_id AND course_section_id = p_course_section_id;

    SELECT 'Đã xóa sinh viên khỏi lớp học phần!' AS message;
END$$

CREATE PROCEDURE `CancelSchedule`(
    IN p_schedule_id BIGINT
)
BEGIN
    DECLARE v_status schedule_status_enum;

    -- Lấy trạng thái hiện tại của lịch học
    SELECT status INTO v_status
    FROM schedule
    WHERE id = p_schedule_id;

    -- Kiểm tra nếu trạng thái là IN_PROGRESS thì mới cho phép huỷ
    IF v_status = 'IN_PROGRESS' THEN
        UPDATE schedule
        SET status = 'CANCELLED'
        WHERE id = p_schedule_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertStudentOnClass`(
    IN p_student_id BIGINT,
    IN p_class_id BIGINT,
    IN p_status ENUM('ENROLLED','COMPLETED','DROPPED')
)
BEGIN
    -- Kiểm tra tồn tại student_id
    IF NOT EXISTS (SELECT 1 FROM student_account WHERE id = p_student_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tồn tại sinh viên với ID đã cho.';
    
    -- Kiểm tra tồn tại class_id
    ELSEIF NOT EXISTS (SELECT 1 FROM class WHERE id = p_class_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tồn tại lớp với ID đã cho.';

    -- Kiểm tra bản ghi đã tồn tại
    ELSEIF EXISTS (
        SELECT 1 FROM student_on_class 
        WHERE student_id = p_student_id AND class_id = p_class_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Sinh viên đã được ghi danh vào lớp này.';

    ELSE
        -- Chèn bản ghi mới
        INSERT INTO student_on_class (student_id, class_id, status)
        VALUES (p_student_id, p_class_id, p_status);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteStudentOnClass`(
    IN p_student_id BIGINT,
    IN p_class_id BIGINT
)
BEGIN
    -- Kiểm tra bản ghi có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM student_on_class 
        WHERE student_id = p_student_id AND class_id = p_class_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy bản ghi sinh viên trong lớp để xóa.';
    ELSE
        -- Xóa bản ghi
        DELETE FROM student_on_class
        WHERE student_id = p_student_id AND class_id = p_class_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSubject`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subject WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy môn học.';
    ELSEIF EXISTS (SELECT 1 FROM course WHERE subject_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa vì môn học đang được sử dụng trong khóa học.';
    ELSE
        DELETE FROM subject WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertSubject`(
    IN p_code VARCHAR(36),
    IN p_name VARCHAR(100),
    IN p_total_credits INT,
    IN p_total_theory INT,
    IN p_total_practice INT,
    IN p_total_exercise INT,
    IN p_total_self_study INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM subject WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã môn học đã tồn tại.';
    ELSEIF EXISTS (SELECT 1 FROM subject WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên môn học đã tồn tại.';
    ELSEIF p_total_credits <= 0 OR p_total_theory <= 0 OR p_total_practice <= 0 OR 
           p_total_exercise <= 0 OR p_total_self_study <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tất cả giá trị số phải lớn hơn 0.';
    ELSE
        INSERT INTO subject (
            code, name, total_credits,
            total_theory_periods, total_practice_periods,
            total_exercise_periods, total_self_study_periods
        ) VALUES (
            p_code, p_name, p_total_credits,
            p_total_theory, p_total_practice,
            p_total_exercise, p_total_self_study
        );
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateSubject`(
    IN p_id BIGINT,
    IN p_code VARCHAR(36),
    IN p_name VARCHAR(100),
    IN p_total_credits INT,
    IN p_total_theory INT,
    IN p_total_practice INT,
    IN p_total_exercise INT,
    IN p_total_self_study INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subject WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy môn học.';
    ELSEIF EXISTS (SELECT 1 FROM subject WHERE code = p_code AND id != p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã môn học đã tồn tại.';
    ELSEIF EXISTS (SELECT 1 FROM subject WHERE name = p_name AND id != p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên môn học đã tồn tại.';
    ELSEIF p_total_credits <= 0 OR p_total_theory <= 0 OR p_total_practice <= 0 OR 
           p_total_exercise <= 0 OR p_total_self_study <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tất cả giá trị số phải lớn hơn 0.';
    ELSE
        UPDATE subject
        SET code = p_code,
            name = p_name,
            total_credits = p_total_credits,
            total_theory_periods = p_total_theory,
            total_practice_periods = p_total_practice,
            total_exercise_periods = p_total_exercise,
            total_self_study_periods = p_total_self_study
        WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSpecialization`(IN p_id BIGINT)
BEGIN
    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM specialization WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy chuyên ngành để xóa.';
        
    -- Kiểm tra ràng buộc với bảng class
    ELSEIF EXISTS (SELECT 1 FROM class WHERE specialization_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa chuyên ngành vì đã được sử dụng trong bảng lớp.';
        
    ELSE
        DELETE FROM specialization WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertSpecialization`(
    IN p_id BIGINT,
    IN p_name VARCHAR(100),
    IN p_major_id BIGINT
)
BEGIN
    -- Kiểm tra id đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM specialization WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID chuyên ngành đã tồn tại.';
        
    -- Kiểm tra tên trùng trong cùng ngành
    ELSEIF EXISTS (SELECT 1 FROM specialization WHERE name = p_name AND major_id = p_major_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên chuyên ngành đã tồn tại trong ngành này.';
        
    -- Kiểm tra ngành có tồn tại không
    ELSEIF NOT EXISTS (SELECT 1 FROM major WHERE id = p_major_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngành không tồn tại.';
        
    ELSE
        INSERT INTO specialization (id, name, major_id)
        VALUES (p_id, p_name, p_major_id);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateSpecialization`(
    IN p_id BIGINT,
    IN p_name VARCHAR(100),
    IN p_major_id BIGINT
)
BEGIN
    -- Kiểm tra chuyên ngành có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM specialization WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Chuyên ngành không tồn tại.';
        
    -- Kiểm tra tên trùng trong cùng ngành
    ELSEIF EXISTS (
        SELECT 1 FROM specialization
        WHERE name = p_name AND major_id = p_major_id AND id != p_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên chuyên ngành đã tồn tại trong ngành này.';
    
    -- Kiểm tra ngành có tồn tại không
    ELSEIF NOT EXISTS (SELECT 1 FROM major WHERE id = p_major_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngành không tồn tại.';
        
    ELSE
        UPDATE specialization
        SET name = p_name,
            major_id = p_major_id
        WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteRoom`(
    IN room_id BIGINT
)
BEGIN
    -- Kiểm tra xem phòng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM room WHERE id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng không tồn tại.';
    END IF;

    -- Kiểm tra xem phòng có được sử dụng trong schedule không
    IF EXISTS (SELECT 1 FROM schedule WHERE room_id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng đã có thông tin liên kết, không thể xóa.';
    END IF;

    -- Xóa phòng
    DELETE FROM room WHERE id = room_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertRoom`(
    IN room_name VARCHAR(36),
    IN room_capacity INT,
    IN room_status ENUM('AVAILABLE', 'UNAVAILABLE', 'REPAIRING'),
    IN room_description VARCHAR(255),
    IN room_type ENUM('LECTURE_HALL', 'COMPUTER_LAB')
)
BEGIN
    -- Kiểm tra capacity > 0
    IF room_capacity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sức chứa tối đa phải lớn hơn 0,';
    END IF;

    -- Thêm phòng vào bảng room
    INSERT INTO room (name, capacity, status, description, type)
    VALUES (room_name, room_capacity, room_status, room_description, room_type);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateRoom`(
    IN room_id BIGINT,
    IN room_name VARCHAR(36),
    IN room_capacity INT,
    IN room_status ENUM('AVAILABLE', 'UNAVAILABLE', 'REPAIRING'),
    IN room_description VARCHAR(255)
)
BEGIN
    -- Kiểm tra xem phòng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM room WHERE id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng không tồn tại.';
    END IF;

    -- Kiểm tra capacity > 0
    IF room_capacity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sức chứa tối đa phải lớn hơn 0.';
    END IF;

    -- Cập nhật phòng
    UPDATE room
    SET name = room_name,
        capacity = room_capacity,
        status = room_status,
        description = room_description
    WHERE id = room_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteMajor`(IN p_id BIGINT)
BEGIN
    -- Kiểm tra ngành có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM major WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy ngành để xóa.';
    
    -- Kiểm tra ràng buộc với specialization
    ELSEIF EXISTS (SELECT 1 FROM specialization WHERE major_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa ngành vì đã được sử dụng trong bảng chuyên ngành (specialization).';
    
    -- Kiểm tra ràng buộc với class
    ELSEIF EXISTS (SELECT 1 FROM class WHERE major_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa ngành vì đã được sử dụng trong bảng lớp (class).';
    
    ELSE
        DELETE FROM major WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertMajor`(
    IN p_code VARCHAR(255),
    IN p_name VARCHAR(255),
    IN p_department_id BIGINT
)
BEGIN
    -- Kiểm tra mã ngành đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM major WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã ngành đã tồn tại.';
    
    -- Kiểm tra tên ngành đã tồn tại chưa
    ELSEIF EXISTS (SELECT 1 FROM major WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên ngành đã tồn tại.';
    
    -- Kiểm tra khoa có tồn tại không
    ELSEIF NOT EXISTS (SELECT 1 FROM department WHERE id = p_department_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Khoa không tồn tại.';
    
    ELSE
        INSERT INTO major (code, name, department_id)
        VALUES (p_code, p_name, p_department_id);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateMajor`(
    IN p_id BIGINT,
    IN p_code VARCHAR(255),
    IN p_name VARCHAR(255),
    IN p_department_id BIGINT
)
BEGIN
    -- Kiểm tra ngành có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM major WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngành không tồn tại.';
    
    -- Kiểm tra mã ngành trùng (nếu cập nhật)
    ELSEIF EXISTS (SELECT 1 FROM major WHERE code = p_code AND id != p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã ngành đã tồn tại.';
    
    -- Kiểm tra tên ngành trùng
    ELSEIF EXISTS (SELECT 1 FROM major WHERE name = p_name AND id != p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên ngành đã tồn tại.';
    
    -- Kiểm tra khoa có tồn tại không
    ELSEIF NOT EXISTS (SELECT 1 FROM department WHERE id = p_department_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Khoa không tồn tại.';
    
    ELSE
        UPDATE major
        SET code = p_code,
            name = p_name,
            department_id = p_department_id
        WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteLecturerOnCourse`(
    IN p_course_id BIGINT,
    IN p_lecturer_id BIGINT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM lecturer_on_course 
        WHERE course_id = p_course_id AND lecturer_id = p_lecturer_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không tồn tại bản ghi để xóa.';
    ELSE
        DELETE FROM lecturer_on_course
        WHERE course_id = p_course_id AND lecturer_id = p_lecturer_id;
    END IF;
END$$

CREATE PROCEDURE `getLecturersByCourseId`(
    IN p_course_id BIGINT
)
BEGIN
    SELECT 
        l.account_id,
        l.code AS lecturer_code,
        l.full_name AS lecturer_name,
        l.email,
        l.phone,
        d.name AS department_name
    FROM lecturer_account l
    JOIN lecturer_on_course loc ON l.account_id = loc.lecturer_id
    JOIN course c ON loc.course_id = c.id
    JOIN department d ON l.department_id = d.id
    WHERE c.id = p_course_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertLecturerOnCourse`(
    IN p_course_id BIGINT,
    IN p_lecturer_id BIGINT
)
BEGIN
    -- Kiểm tra tồn tại khóa ngoại
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không tồn tại học phần.';
    ELSEIF NOT EXISTS (SELECT 1 FROM lecturer_account WHERE account_id = p_lecturer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không tồn tại giảng viên.';
    ELSEIF EXISTS (
        SELECT 1 FROM lecturer_on_course 
        WHERE course_id = p_course_id AND lecturer_id = p_lecturer_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên đã được phân công học phần này.';
    ELSE
        INSERT INTO lecturer_on_course(course_id, lecturer_id)
        VALUES (p_course_id, p_lecturer_id);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateCourse`(
    IN p_course_id INT,
    IN p_subject_id INT,
    IN p_class_id INT,
    IN p_semester_id INT,
    IN p_max_students INT,
    IN p_number_of_sections INT
)
BEGIN
    DECLARE base_students_per_section INT;
    DECLARE remainder INT;
    DECLARE i INT DEFAULT 1;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '❌ Course không tồn tại.';
    END IF;

    -- Cập nhật course
    UPDATE course
    SET subject_id = p_subject_id,
        class_id = p_class_id,
        semester_id = p_semester_id,
        max_students = p_max_students
    WHERE id = p_course_id;

    -- Xóa tất cả các nhóm cũ trong course_section
    DELETE FROM course_section WHERE course_id = p_course_id;

    -- Tính toán chia lại nhóm
    SET base_students_per_section = FLOOR(p_max_students / p_number_of_sections);
    SET remainder = p_max_students MOD p_number_of_sections;

    -- Thêm lại các nhóm
    WHILE i <= p_number_of_sections DO
        INSERT INTO course_section (course_id, section_number, max_students_in_section)
        VALUES (
            p_course_id,
            i,
            IF(i <= remainder, base_students_per_section + 1, base_students_per_section)
        );
        SET i = i + 1;
    END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteCourse`(
    IN p_id BIGINT
)
BEGIN
    -- Kiểm tra xem học phần có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không tìm thấy học phần để xóa.';
    ELSE
        -- Kiểm tra xem có lịch học nào đang sử dụng học phần này không
        IF EXISTS (SELECT 1 FROM schedule WHERE course_id = p_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể xóa học phần này vì đã có lịch học liên quan.';
        -- Kiểm tra xem có giảng viên nào đang giảng dạy học phần này không
        ELSEIF EXISTS (SELECT 1 FROM lecturer_on_course WHERE course_id = p_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể xóa học phần này vì đã có giảng viên liên quan.';
        ELSE
            -- Xóa học phần nếu không có liên kết với các bảng khác
            DELETE FROM course WHERE id = p_id;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertCourse`(
    IN p_subject_id BIGINT,
    IN p_class_id BIGINT,
    IN p_semester_id BIGINT,
    IN p_max_students INT,
    IN p_number_of_sections INT
)
BEGIN
    DECLARE v_group_number INT;
    DECLARE v_course_id INT;
    DECLARE i INT DEFAULT 1;
    DECLARE base_students_per_section INT;
    DECLARE remainder INT;

    -- Tìm group_number kế tiếp (nếu đã tồn tại course cùng subject và semester)
    SELECT IFNULL(MAX(group_number), 0) + 1
    INTO v_group_number
    FROM course
    WHERE subject_id = p_subject_id AND semester_id = p_semester_id;

    -- Thêm vào bảng course
    INSERT INTO course (subject_id, class_id, semester_id, group_number, max_students)
    VALUES (p_subject_id, p_class_id, p_semester_id, v_group_number, p_max_students);

    SET v_course_id = LAST_INSERT_ID();

    -- Tính toán chia nhóm
    SET base_students_per_section = FLOOR(p_max_students / p_number_of_sections);
    SET remainder = p_max_students MOD p_number_of_sections;

    -- Thêm các bản ghi course_section tương ứng
    WHILE i <= p_number_of_sections DO
        INSERT INTO course_section (course_id, section_number, max_students_in_section)
        VALUES (
            v_course_id,
            i,
            IF(i <= remainder, base_students_per_section + 1, base_students_per_section)
        );
        SET i = i + 1;
    END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteClass`(IN p_id BIGINT)
BEGIN
    -- Kiểm tra lớp tồn tại
    IF NOT EXISTS (SELECT 1 FROM class WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy lớp để xóa.';

    -- Ràng buộc với course
    ELSEIF EXISTS (SELECT 1 FROM course WHERE class_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa lớp vì đã được sử dụng trong bảng khóa học.';

    -- Ràng buộc với student_on_class
    ELSEIF EXISTS (SELECT 1 FROM student_on_class WHERE class_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa lớp vì đã có sinh viên đăng ký lớp.';

    ELSE
        DELETE FROM class WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertClass`(
    IN p_name VARCHAR(50),
    IN p_major_id BIGINT,
    IN p_specialization_id BIGINT,
    IN p_class_type ENUM('MAJOR', 'SPECIALIZATION')
)
BEGIN
    -- Kiểm tra tên lớp trùng
    IF EXISTS (SELECT 1 FROM class WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên lớp đã tồn tại.';

    -- Kiểm tra major_id tồn tại
    ELSEIF NOT EXISTS (SELECT 1 FROM major WHERE id = p_major_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngành không tồn tại.';

    -- Kiểm tra class_type là SPECIALIZATION thì specialization_id không được NULL
    ELSEIF p_class_type = 'SPECIALIZATION' AND p_specialization_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lớp chuyên ngành cần có chuyên ngành.';

    -- Nếu loại là MAJOR mà specialization_id lại không NULL
    ELSEIF p_class_type = 'MAJOR' AND p_specialization_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lớp ngành không được gán chuyên ngành.';

    -- Nếu có specialization_id thì kiểm tra có tồn tại
    ELSEIF p_specialization_id IS NOT NULL AND 
           NOT EXISTS (SELECT 1 FROM specialization WHERE id = p_specialization_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Chuyên ngành không tồn tại.';
        
    ELSE
        INSERT INTO class (name, major_id, specialization_id, class_type)
        VALUES (p_name, p_major_id, p_specialization_id, p_class_type);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateClass`(
    IN p_id BIGINT,
    IN p_name VARCHAR(50),
    IN p_major_id BIGINT,
    IN p_specialization_id BIGINT,
    IN p_class_type ENUM('MAJOR', 'SPECIALIZATION')
)
BEGIN
    -- Kiểm tra lớp có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM class WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lớp không tồn tại.';

    -- Kiểm tra tên lớp trùng với lớp khác
    ELSEIF EXISTS (
        SELECT 1 FROM class WHERE name = p_name AND id != p_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên lớp đã tồn tại.';

    -- Kiểm tra major_id tồn tại
    ELSEIF NOT EXISTS (SELECT 1 FROM major WHERE id = p_major_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngành không tồn tại.';

    -- Kiểm tra specialization_id nếu có
    ELSEIF p_specialization_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM specialization WHERE id = p_specialization_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Chuyên ngành không tồn tại.';
        
    ELSE
        UPDATE class
        SET name = p_name,
            major_id = p_major_id,
            specialization_id = p_specialization_id,
            class_type = p_class_type
        WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteDepartment`(IN p_id BIGINT)
BEGIN
    -- Kiểm tra sự tồn tại của department
    IF NOT EXISTS (SELECT 1 FROM department WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy khoa để xóa.';
    
    -- Kiểm tra xem department có đang được sử dụng ở bảng major hoặc lecturer_account không
    ELSEIF EXISTS (SELECT 1 FROM major WHERE department_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa khoa vì đã được sử dụng trong bảng ngành (major).';
        
    ELSEIF EXISTS (SELECT 1 FROM lecturer_account WHERE department_id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa khoa vì đã được sử dụng trong bảng giảng viên (lecturer_account).';
        
    -- Nếu không bị ràng buộc, cho phép xóa
    ELSE
        DELETE FROM department WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateDepartment`(IN p_id BIGINT, IN p_name VARCHAR(50))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM department WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy khoa để cập nhật.';
    ELSEIF EXISTS (SELECT 1 FROM department WHERE name = p_name AND id != p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên khoa đã tồn tại.';
    ELSE
        UPDATE department SET name = p_name WHERE id = p_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ResetPassword`(
    IN p_account_id BIGINT
)
BEGIN
    DECLARE v_username VARCHAR(100);
    DECLARE v_sql VARCHAR(500);

    -- Kiểm tra tài khoản có tồn tại và lấy username
    SELECT username INTO v_username
    FROM account
    WHERE id = p_account_id;

    IF v_username IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không tồn tại!';
    ELSE
        -- Cập nhật mật khẩu trong bảng account
        UPDATE account
        SET password = SHA2('123', 256)
        WHERE id = p_account_id;

        -- Thay đổi mật khẩu user MySQL
        SET @sql = CONCAT('ALTER USER \'', v_username, '\'@\'localhost\' IDENTIFIED BY \'123\';');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateReportLog`(
    IN p_report_id BIGINT,
    IN p_new_status ENUM('APPROVED', 'REJECTED'),
    IN p_content TEXT,
    IN p_manager_id BIGINT
)
BEGIN
    -- Kiểm tra trạng thái hiện tại có phải là 'PENDING'
    IF NOT EXISTS (
        SELECT 1 FROM report_log
        WHERE report_id = p_report_id AND status = 'PENDING'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Chỉ được cập nhật khi trạng thái hiện tại là PENDING.';
    END IF;

    -- Kiểm tra manager_id có tồn tại và có role là 1 không
    IF NOT EXISTS (
        SELECT 1 FROM account
        WHERE id = p_manager_id AND role_id = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Người duyệt không hợp lệ (phải có vai trò quản lý).';
    END IF;

    -- Cập nhật report_log
    UPDATE report_log
    SET
        status = p_new_status,
        content = p_content,
        manager_id = p_manager_id
    WHERE report_id = p_report_id AND status = 'PENDING';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertReport`(
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_author_id BIGINT
)
BEGIN
    -- Kiểm tra author_id có tồn tại trong bảng account không
    IF NOT EXISTS (SELECT 1 FROM account WHERE id = p_author_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
    END IF;

    -- Kiểm tra role của author_id có phải là 2 không
    IF NOT EXISTS (
        SELECT 1
        FROM account
        WHERE id = p_author_id AND role_id = 2
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Tài khoản không có quyền tạo báo cáo.';
    END IF;

    -- Thêm báo cáo mới
    INSERT INTO report (title, content, author_id)
    VALUES (p_title, p_content, p_author_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ChangePassword`(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_new_password VARCHAR(255)
)
BEGIN
    DECLARE v_account_id BIGINT DEFAULT NULL;
    DECLARE v_password_hashed VARCHAR(255);
    DECLARE v_new_password_hashed VARCHAR(255);
    DECLARE v_sql VARCHAR(500);

    -- Mã hóa mật khẩu cũ và mới
    SET v_password_hashed = SHA2(p_password, 256);
    SET v_new_password_hashed = SHA2(p_new_password, 256);

    -- Kiểm tra thông tin đăng nhập
    SELECT id INTO v_account_id
    FROM account
    WHERE username = p_username AND password = v_password_hashed
    LIMIT 1;

    -- Nếu không tìm thấy tài khoản
    IF v_account_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên đăng nhập hoặc mật khẩu không đúng!';
    ELSE
        -- Cập nhật mật khẩu mới trong bảng account
        UPDATE account
        SET password = v_new_password_hashed
        WHERE id = v_account_id;

        -- Đổi mật khẩu user MySQL (mật khẩu thẳng, MySQL tự mã hóa)
        SET @sql = CONCAT('ALTER USER \'', p_username, '\'@\'localhost\' IDENTIFIED BY \'', p_new_password, '\';');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SELECT 'Đổi mật khẩu thành công!' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ChangeStatusAccount`(
    IN p_account_id BIGINT
)
BEGIN
    DECLARE v_current_status ENUM('ACTIVE', 'LOCKED');

    -- Kiểm tra tài khoản tồn tại
    SELECT status INTO v_current_status
    FROM account
    WHERE id = p_account_id;

    -- Nếu không có kết quả
    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không tồn tại!';
    ELSE
        -- Đổi trạng thái
        UPDATE account
        SET status = CASE 
                        WHEN v_current_status = 'ACTIVE' THEN 'LOCKED'
                        ELSE 'ACTIVE'
                    END
        WHERE id = p_account_id;
    END IF;
END$$

CREATE PROCEDURE `GetAllSchedulesByCourseId`(
    IN p_course_id BIGINT
)
BEGIN
    SELECT
        sch.id AS schedule_id,
        sch.day_of_week,
        sch.start_period,
        sch.total_period,
        sch.status,
        sch.type,
        sch.course_section_id,
        sw.name AS semester_week_name,
        sw.start_date,
        sw.end_date,
        r.name AS room_name,
        r.type AS room_type,
        l.full_name AS lecturer_name
    FROM schedule sch
    JOIN semester_week sw ON sch.semester_week_id = sw.id
    JOIN room r ON sch.room_id = r.id
    JOIN lecturer_account l ON sch.lecturer_id = l.account_id
    WHERE sch.course_id = p_course_id
    ORDER BY sw.start_date, sch.day_of_week, sch.start_period;
END$$

DELIMITER ;