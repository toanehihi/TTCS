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
