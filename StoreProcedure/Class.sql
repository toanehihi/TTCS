-- Xóa class
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
END

--Lấy tất cả class
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllClasses`()
BEGIN
    SELECT * FROM class;
END

--Lấy class qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetClassById`(IN p_id BIGINT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM class WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không tìm thấy lớp.';
    ELSE
        SELECT * FROM class WHERE id = p_id;
    END IF;
END

--Thêm class
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
END

--Cập nhật thông tin của class
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
END

-- Insert sinh viên vào lớp
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
END

-- Xóa sinh viên khỏi lớp
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
END

--get all student on class
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllStudentOnClass`(
)
BEGIN
    select * from student_on_class;
END

-- get all student on class by class id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetStudentOnClassByClassId`(
    IN p_class_id BIGINT
)
BEGIN
    -- Kiểm tra lớp học có tồn tại
    IF NOT EXISTS (SELECT 1 FROM class WHERE id = p_class_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy lớp học.';
    ELSE
        -- Lấy danh sách sinh viên theo lớp học
        SELECT s.id, s.code, s.full_name, s.email, s.phone, s.gender, s.birthday, soc.status
        FROM student_on_class soc
        JOIN student_account s ON soc.student_id = s.id
        WHERE soc.class_id = p_class_id;
    END IF;
END;