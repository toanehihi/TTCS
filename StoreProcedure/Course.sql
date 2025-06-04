--Xóa course
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteCourse`(
    IN p_id BIGINT
)
BEGIN
    -- Kiểm tra xem học phần có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không tìm thấy học phần để xóa.';
    ELSE
        -- Kiểm tra xem có lịch học nào đang sử dụng học phần này không
        IF EXISTS (SELECT 1 FROM schedule WHERE course_id = p_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể xóa học phần này vì đã có lịch học liên quan.';
        -- Kiểm tra xem có giảng viên nào đang giảng dạy học phần này không
        ELSEIF EXISTS (SELECT 1 FROM lecturer_on_course WHERE course_id = p_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể xóa học phần này vì đã có giảng viên liên quan.';
        ELSE
            -- Xóa học phần nếu không có liên kết với các bảng khác
            DELETE FROM course WHERE id = p_id;
        END IF;
    END IF;
END

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



--Lấy tất cả course
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllCourses`()
BEGIN
    SELECT * FROM course;
END

--Lấy course qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCourseById`(IN p_id BIGINT)
BEGIN
    SELECT * FROM course WHERE id = p_id;
END

--Thêm course và tự động chia nhỏ nhóm và thêm vào course_section
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertCourse`(
    IN p_subject_id BIGINT,
    IN p_class_id BIGINT,
    IN p_semester_id BIGINT,
    IN p_total_students INT,
    IN p_number_of_sections INT
)
BEGIN
    DECLARE v_group_number INT;
    DECLARE v_course_id INT;
    DECLARE i INT DEFAULT 1;
    DECLARE base_students_per_section INT;
    DECLARE remainder INT;

    -- Tìm group_number kế tiếp (nếu đã tồn tại course cùng subject và semester)
    SELECT IFNULL(MAX(group_number), 0) + 1
    INTO v_group_number
    FROM course
    WHERE subject_id = p_subject_id AND semester_id = p_semester_id;

    -- Thêm vào bảng course
    INSERT INTO course (subject_id, class_id, semester_id, group_number, total_students)
    VALUES (p_subject_id, p_class_id, p_semester_id, v_group_number, p_total_students);

    SET v_course_id = LAST_INSERT_ID();

    -- Tính toán chia nhóm
    SET base_students_per_section = FLOOR(p_total_students / p_number_of_sections);
    SET remainder = p_total_students MOD p_number_of_sections;

    -- Thêm các bản ghi course_section tương ứng
    WHILE i <= p_number_of_sections DO
        INSERT INTO course_section (course_id, section_number, total_students_in_section)
        VALUES (
            v_course_id,
            i,
            IF(i <= remainder, base_students_per_section + 1, base_students_per_section)
        );
        SET i = i + 1;
    END WHILE;
END

--Cập nhật thông tin của course
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateCourse`(
    IN p_course_id INT,
    IN p_subject_id INT,
    IN p_class_id INT,
    IN p_semester_id INT,
    IN p_total_students INT,
    IN p_number_of_sections INT
)
BEGIN
    DECLARE base_students_per_section INT;
    DECLARE remainder INT;
    DECLARE i INT DEFAULT 1;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '❌ Course không tồn tại.';
    END IF;

    -- Cập nhật course
    UPDATE course
    SET subject_id = p_subject_id,
        class_id = p_class_id,
        semester_id = p_semester_id,
        total_students = p_total_students
    WHERE id = p_course_id;

    -- Xóa tất cả các nhóm cũ trong course_section
    DELETE FROM course_section WHERE course_id = p_course_id;

    -- Tính toán chia lại nhóm
    SET base_students_per_section = FLOOR(p_total_students / p_number_of_sections);
    SET remainder = p_total_students MOD p_number_of_sections;

    -- Thêm lại các nhóm
    WHILE i <= p_number_of_sections DO
        INSERT INTO course_section (course_id, section_number, total_students_in_section)
        VALUES (
            p_course_id,
            i,
            IF(i <= remainder, base_students_per_section + 1, base_students_per_section)
        );
        SET i = i + 1;
    END WHILE;
END

-- Insert Student vào course
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertStudentOnCourse`(
    IN p_student_id BIGINT,
    IN p_course_id BIGINT
)
BEGIN
    -- Kiểm tra sinh viên có tồn tại
    IF NOT EXISTS (SELECT 1 FROM student_account WHERE id = p_student_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy sinh viên.';
    
    -- Kiểm tra môn học có tồn tại
    ELSEIF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy môn học.';
    
    -- Kiểm tra đã tồn tại bản ghi
    ELSEIF EXISTS (
        SELECT 1 FROM student_on_course 
        WHERE student_id = p_student_id AND course_id = p_course_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Sinh viên đã đăng ký môn học này.';
    
    ELSE
        -- Chèn bản ghi
        INSERT INTO student_on_course (student_id, course_id)
        VALUES (p_student_id, p_course_id);
    END IF;
END;

--get all student on course
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllStudentOnCourse`(
)
BEGIN
    select * from student_on_course;
END

--get all student on course by course_id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetStudentOnCourseByCourseId`(
    IN p_course_id BIGINT
)
BEGIN
    -- Kiểm tra môn học có tồn tại
    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không tìm thấy môn học.';
    ELSE
        -- Lấy danh sách sinh viên theo môn học
        SELECT s.id, s.code, s.full_name, s.email, s.phone, s.gender, s.birthday
        FROM student_on_course soc
        JOIN student_account s ON soc.student_id = s.id
        WHERE soc.course_id = p_course_id;
    END IF;
END;