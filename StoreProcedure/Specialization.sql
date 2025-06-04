--Xóa specialization
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
END

--Lấy tất cả Specializations
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllSpecializations`()
BEGIN
    SELECT * FROM specialization;
END

--Lấy SpecializationById qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSpecializationById`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM specialization WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy chuyên ngành.';
    ELSE
        SELECT * FROM specialization WHERE id = p_id;
    END IF;
END

--Thêm Specialization
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
END

--Cập nhật thông tin Specialization
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
END