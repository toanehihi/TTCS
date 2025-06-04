--Xóa schedule
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSchedule`(
    IN p_schedule_id BIGINT
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_start_date DATE;
    DECLARE v_day_of_week TINYINT;
    DECLARE v_status VARCHAR(50);
    DECLARE v_target_date DATE;
    DECLARE v_semester_week_id BIGINT;
    DECLARE v_error_message VARCHAR(255); -- Thêm biến để chứa thông báo lỗi

    -- Kiểm tra tồn tại lịch
    SELECT COUNT(*) INTO v_count
    FROM schedule
    WHERE id = p_schedule_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lịch học không tồn tại.';
    END IF;

    -- Lấy thông tin cần thiết
    SELECT s.day_of_week, s.status, s.semester_week_id
    INTO v_day_of_week, v_status, v_semester_week_id
    FROM schedule s
    WHERE s.id = p_schedule_id;

    SELECT start_date INTO v_start_date
    FROM semester_week
    WHERE id = v_semester_week_id;

    -- Tính ngày học cụ thể
    SET v_target_date = DATE_ADD(v_start_date, INTERVAL v_day_of_week - 2 DAY);

    -- Kiểm tra điều kiện ngày
    IF v_target_date <= CURRENT_DATE() THEN
        SET v_error_message = CONCAT('Không thể xóa vì ngày học ', DATE_FORMAT(v_target_date, '%Y-%m-%d'), ' đã qua.');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Kiểm tra trạng thái
    IF v_status != 'IN_PROGRESS' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Chỉ có thể xóa lịch học đang ở trạng thái IN_PROGRESS.';
    END IF;

    -- Xóa lịch
    DELETE FROM schedule
    WHERE id = p_schedule_id;
END

--Lấy tất cả schedule
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllSchedule`()
BEGIN
    SELECT * FROM schedule;
END

--Lấy schedule bằng Id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetScheduleById`(
    IN p_schedule_id BIGINT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count FROM schedule WHERE id = p_schedule_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lịch học không tồn tại.';
    END IF;

    SELECT * FROM schedule WHERE id = p_schedule_id;
END

--Thêm schedule
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
    SET v_target_date = DATE_ADD(v_start_date, INTERVAL p_day_of_week - 2 DAY); -- thứ 2 là day_of_week = 2

    -- Kiểm tra nếu ngày đã qua
    IF v_target_date <= CURRENT_DATE() THEN
        SET v_message = CONCAT('Không thể thêm lịch vì ngày ', DATE_FORMAT(v_target_date, '%d-%m-%Y'), ' đã qua.');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_message;
    END IF;

    -- Kiểm tra trùng lịch phòng học
    SELECT COUNT(*) INTO v_count
    FROM schedule
    WHERE room_id = p_room_id
      AND semester_week_id = p_semester_week_id
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