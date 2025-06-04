--Xóa department
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
END

--Lấy tất cả department
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllDepartments`()
BEGIN
    SELECT * FROM department;
END

--Lấy department qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetDepartmentById`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM department WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy khoa với ID đã cho.';
    ELSE
        SELECT * FROM department WHERE id = p_id;
    END IF;
END

--Thêm department
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertDepartment`(IN p_name VARCHAR(50))
BEGIN
    IF EXISTS (SELECT 1 FROM department WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tên khoa đã tồn tại.';
    ELSE
        INSERT INTO department (name) VALUES (p_name);
    END IF;
END

--Cập nhật thông tin của department
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
END