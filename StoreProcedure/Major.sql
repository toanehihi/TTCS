--Xóa major
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
END

--Lấy tất cả major
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllMajors`()
BEGIN
    SELECT * FROM major;
END

--Lấy major qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetMajorById`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM major WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy ngành.';
    ELSE
        SELECT * FROM major WHERE id = p_id;
    END IF;
END

--Thêm major
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
END

--Cập nhật thông tin major
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
END