--Xóa LecturerOnCourse
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
END

--Lấy tất cả LecturerOnCourse
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllLecturerOnCourse`()
BEGIN
    SELECT * FROM lecturer_on_course;
END

--Lấy LecturerOnCourse phù hợp
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetLecturerOnCourseById`(
    IN p_course_id BIGINT,
    IN p_lecturer_id BIGINT
)
BEGIN
    SELECT * FROM lecturer_on_course
    WHERE course_id = p_course_id AND lecturer_id = p_lecturer_id;
END

--Thêm LecturerOnCourse
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
END 