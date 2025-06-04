--Xóa subject
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
END

--Lấy tất cả subject
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllSubject`()
BEGIN
    SELECT * FROM subject;
END

--Lấy subject qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSubjectById`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subject WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy môn học.';
    ELSE
        SELECT * FROM subject WHERE id = p_id;
    END IF;
END

--Thêm subject
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
END

--Cập nhật thông tin subject
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
END