--Xóa StudentOnCourse
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
END