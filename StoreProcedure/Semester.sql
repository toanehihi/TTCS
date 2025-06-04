--Xóa semester và semester_week tương ứng của semester đó
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSemester`(
    IN p_code VARCHAR(36)
)
BEGIN
    DECLARE v_id BIGINT;

    -- Lấy id học kỳ theo mã
    SELECT id INTO v_id FROM semester WHERE code = p_code;

    -- Nếu không tìm thấy học kỳ
    IF v_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy học kỳ để xóa.';

    -- Nếu học kỳ đã được sử dụng trong bảng course
    ELSEIF EXISTS (SELECT 1 FROM course WHERE semester_id = v_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa học kỳ vì đã được sử dụng trong bảng môn học.';

    ELSE
        -- Xóa các tuần học tương ứng trước
        DELETE FROM semester_week WHERE semester_id = v_id;

        -- Sau đó xóa học kỳ
        DELETE FROM semester WHERE id = v_id;
    END IF;
END

--Lấy tất cả semester
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllSemesters`()
BEGIN
    SELECT * FROM semester;
END

--Thêm semester và sẽ tự động thêm các semester_week tương ứng với semester vừa thêm
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertSemester`(
    IN p_code VARCHAR(36),
    IN p_name VARCHAR(36),
    IN p_start_date TIMESTAMP,
    IN p_end_date TIMESTAMP,
    IN p_start_week INT
)
BEGIN
    DECLARE v_latest_end TIMESTAMP;
    DECLARE v_semester_id INT;
    DECLARE v_week_start_date DATE;
    DECLARE v_week_end_date DATE;
    DECLARE v_week_number INT DEFAULT 0;

    -- Lấy ngày kết thúc học kỳ hiện tại (nếu có)
    SELECT MAX(end_date) INTO v_latest_end FROM semester;

    -- Kiểm tra mã học kỳ đã tồn tại
    IF EXISTS (SELECT 1 FROM semester WHERE code = p_code) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã học kỳ đã tồn tại.';

    -- Kiểm tra tên học kỳ đã tồn tại
    ELSEIF EXISTS (SELECT 1 FROM semester WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên học kỳ đã tồn tại.';

    -- Kiểm tra thời gian không hợp lệ
    ELSEIF p_start_date >= p_end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngày bắt đầu phải nhỏ hơn ngày kết thúc.';

    -- Kiểm tra không được trùng với học kỳ trước
    ELSEIF v_latest_end IS NOT NULL AND p_start_date <= v_latest_end THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngày bắt đầu của học kỳ mới phải sau ngày kết thúc học kỳ hiện tại.';

    ELSE
        -- Thêm học kỳ
        INSERT INTO semester(code, name, start_date, end_date)
        VALUES (p_code, p_name, p_start_date, p_end_date);

        -- Lấy ID học kỳ vừa thêm
        SET v_semester_id = LAST_INSERT_ID();

        -- Gán ngày bắt đầu tuần đầu tiên
        SET v_week_start_date = DATE(p_start_date);
        SET v_week_number = p_start_week;

        -- Lặp để thêm các tuần cho đến khi vượt quá ngày kết thúc học kỳ
        WHILE v_week_start_date <= DATE(p_end_date) DO
            SET v_week_end_date = DATE_ADD(v_week_start_date, INTERVAL 6 DAY);

            -- Nếu tuần kết thúc vượt quá ngày kết thúc học kỳ thì điều chỉnh
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

            -- Tăng ngày bắt đầu tuần tiếp theo và số tuần
            SET v_week_start_date = DATE_ADD(v_week_start_date, INTERVAL 7 DAY);
            SET v_week_number = v_week_number + 1;
        END WHILE;
    END IF;
END

--Cập nhật thông tin semester
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateSemester`(
    IN p_id BIGINT,
    IN p_code VARCHAR(36),
    IN p_name VARCHAR(36)
)
BEGIN
    -- Kiểm tra học kỳ có tồn tại hay không
    IF NOT EXISTS (SELECT 1 FROM semester WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy học kỳ.';
        
    -- Kiểm tra mã học kỳ đã tồn tại cho id khác
    ELSEIF EXISTS (
        SELECT 1 FROM semester WHERE code = p_code AND id != p_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mã học kỳ đã tồn tại.';
        
    -- Kiểm tra tên học kỳ đã tồn tại cho id khác
    ELSEIF EXISTS (
        SELECT 1 FROM semester WHERE name = p_name AND id != p_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên học kỳ đã tồn tại.';

    ELSE
        -- Cập nhật chỉ code và name
        UPDATE semester
        SET code = p_code,
            name = p_name
        WHERE id = p_id;
    END IF;
END