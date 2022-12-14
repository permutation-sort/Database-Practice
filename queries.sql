-- 1.1
SELECT r.room_num AS "Room Number", p.name AS "Patient Name", pa.timestamp AS "Admitted Date & Time"
FROM ROOM r
LEFT JOIN patient_admitted pa
ON r.room_id = pa.room_id
LEFT JOIN patient p
ON p.patient_id = pa.patient_id;

-- 1.2
SELECT room_num AS "Unoccupied Rooms"
FROM room r
WHERE r.occupied=0;
 
-- 1.3
SELECT r.room_num AS "Room Number", p.name AS "Patient Name", pa.timestamp AS "Admitted Date & Time"
FROM ROOM r
LEFT JOIN patient_admitted pa
ON r.room_id = pa.room_id AND r.occupied=1
LEFT JOIN patient p
ON p.patient_id = pa.patient_id;

-- 2.1
SELECT p.name as "Patient Name", e.name as "Emergency Contact Name", e.phone_number as "Emergency Contact Phone", e.relationship as "Emergency Contact Relationship"
FROM patient p
LEFT JOIN Emergency_Contact e
ON p.emergency_contact_id = e.emergency_contact_id;

-- 2.2
SELECT p.name as "Currently Admitted Patient Name", p.patient_id as "Patient ID"
FROM ROOM r
INNER JOIN patient_admitted pa
ON r.room_id = pa.room_id AND r.occupied=1
LEFT JOIN patient p
ON p.patient_id = pa.patient_id;

-- 2.3
SELECT p.patient_id AS "Patient ID", p.name AS "Patient Name"
FROM Patient_Discharged pd
LEFT JOIN Patient p 
ON pd.patient_id = p.patient_id
-- GIVEN DATE RANGE 
WHERE pd.timestamp BETWEEN '2022-02-01 00:00:00' AND '2022-10-01 00:00:00';

-- 2.4
SELECT p.patient_id AS "Patient ID", p.name AS "Patient Name"
FROM Patient_Admitted pd
LEFT JOIN Patient p 
ON pd.patient_id = p.patient_id
-- GIVEN DATE RANGE 
WHERE pd.timestamp BETWEEN '2011-01-01 00:00:00' AND '2015-01-01 00:00:00';

-- 2.5
SELECT pa.timestamp as "Admitted Timestamp", pa.diagnosis as "Diagnosis" 
FROM Patient_Admitted pa
-- GIVEN PATIENT ID or NAME 
WHERE pa.patient_id = 1;


-- Fixing SQL Mode
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
-- 2.6 
SELECT * 
FROM administer_treatment t
LEFT JOIN Patient_Admitted pa
ON t.admit_id = pa.admit_id
WHERE pa.patient_id = 1
ORDER BY t.admit_id DESC, t.treatment_id ASC;

-- 2.7 
Select * FROM 
(SELECT a.patient_id, p.name, a.diagnosis, a.primary_doctor_id as "Admitting Doctor", LAG(d.timestamp, 1) OVER (partition by a.patient_id) AS last_discharge_date, a.timestamp AS Admitted_Timestamp
 FROM patient_admitted a
    LEFT JOIN patient_discharged d ON a.admit_id = d.admit_id
    LEFT JOIN patient p ON p.patient_id = a.patient_id
    LEFT JOIN primary_doctor pd ON pd.primary_doctor_id = a.primary_doctor_id) table1
WHERE TIMESTAMPDIFF(DAY, last_discharge_date, Admitted_Timestamp) < 31 AND TIMESTAMPDIFF(DAY, last_discharge_date, Admitted_Timestamp) >0;

-- 2.8 
SELECT t1.patient_id, t1.total_admissions, t1.name, t2.shortest_span, t2.longest_span, t2.average_span_between_admissions, t4.average_duration FROM
    -- COUNT
    (SELECT p.patient_id, p.name, COUNT(p.patient_id) AS total_admissions FROM patient p 
    LEFT JOIN patient_admitted a ON a.patient_id = p.patient_id
    GROUP BY p.patient_id) t1

LEFT JOIN
    -- SHORTEST/LONGEST/AVERAGE BETWEEN ADMISSIONS 
    (SELECT MIN(DATEDIFF(DATE(next_date), DATE(timestamp))) AS shortest_span, 
    MAX(DATEDIFF(DATE(next_date), DATE(timestamp))) AS longest_span, patient_id, 
    AVG(DATEDIFF(DATE(next_date), DATE(timestamp))) AS average_span_between_admissions 
    FROM
        (SELECT patient_admitted.*, LEAD(timestamp) OVER (PARTITION BY patient_id ORDER BY timestamp) AS next_date
		FROM patient_admitted) a
		GROUP BY patient_id) t2
ON t1.patient_id = t2.patient_id

LEFT JOIN
    -- AVERAGE LENGTH OF ADMISSION
    (SELECT patient_id, AVG(TIMESTAMPDIFF(DAY, admission_time, discharge_time)) AS average_duration FROM 
     (SELECT p.patient_id, p.name, a.admit_id, a.timestamp AS admission_time, d.timestamp AS discharge_time FROM patient p
    LEFT JOIN patient_admitted a ON a.patient_id = p.patient_id
    LEFT JOIN patient_discharged d ON d.admit_id = a.admit_id) t3
     GROUP BY patient_id) t4
ON t2.patient_id = t4.patient_id;


-- 3.1
-- NOTE: I did not use diagnosis ID number in my tables, so I did not provide this ID
SELECT pa.diagnosis as "Diagnosis Name", count(pa.diagnosis) as "Times Occured"
FROM Patient_Admitted pa
WHERE pa.admit_id NOT IN (SELECT admit_id FROM Patient_Discharged)
GROUP BY diagnosis
ORDER BY count(diagnosis) DESC;

-- 3.2
-- NOTE: I did not use diagnosis ID number in my tables, so I did not provide this ID
SELECT pa.diagnosis as "Diagnosis Name", count(pa.diagnosis) as "Times Occured"
FROM Patient_Admitted pa
GROUP BY diagnosis
ORDER BY count(diagnosis) DESC;

-- 3.3
-- NOTE: I did not use treatment name in my tables, so I did not provide this name (only IDs)
SELECT pa.treatment_id as "Treatment ID", count(pa.treatment_id) as "Times Administered"
FROM OrderTreatment pa
WHERE pa.admit_id NOT IN (SELECT admit_id FROM Patient_Discharged)
GROUP BY treatment_id
ORDER BY count(treatment_id) DESC;

-- 3.4
SELECT pa.patient_id, count(pa.patient_id), pa.diagnosis
FROM Patient_Admitted pa
GROUP BY pa.patient_id
HAVING count(patient_id) >= 2
ORDER BY count(pa.patient_id) desc;

-- 3.5
SELECT pa.name AS "Patient Name", o.treatment_id AS "Treatment ID", o.doctor_id AS "Doctor who Ordered Treatment (ID)"
FROM OrderTreatment o
LEFT JOIN Patient_Admitted p
ON o.admit_id = p.admit_id
LEFT JOIN Patient pa
ON p.patient_id = pa.patient_id
;
-- 4.1
SELECT *, (case
when administrator_id != '' then "Admin"
when doctor_id != '' then "Doctor"
when nurse_id != '' then "Nurse"
when technician_id != '' then "Technician"
else NULL end) as type from
employee e
LEFT JOIN doctor d on e.employee_id = d.doctor_id
LEFT JOIN nurse n on e.employee_id = n.nurse_id
LEFT JOIN technician t on e.employee_id = t.technician_id
LEFT JOIN administrator a on e.employee_id = a.administrator_id;

-- 4.2
SELECT pa.primary_doctor_id as "Primary Doctor ID", count(pa.primary_doctor_id) as "Admissions this Year"
FROM Patient_Admitted pa
WHERE (NOW() - pa.timestamp) < 31536000
GROUP BY pa.primary_doctor_id
HAVING count(pa.primary_doctor_id) >= 4;

-- 4.3
SELECT pa.diagnosis as "Dianosis Given", pa.diagnosis_id as "Diagnosis ID", count(pa.diagnosis_id) as "Times Diagnosed"
FROM Patient_Admitted pa 
-- GIVEN DOCTOR ID
WHERE pa.primary_doctor_id = 2
GROUP BY pa.diagnosis_id
ORDER BY count(pa.diagnosis_id) DESC;

-- 4.4
SELECT o.treatment_id as "Treatment ID", count(o.treatment_id) as "Times Ordered" 
FROM OrderTreatment o
-- GIVEN DOCTOR ID
WHERE o.doctor_id = 2
GROUP BY o.treatment_id
ORDER BY count(o.treatment_id) DESC;

-- 4.5
SELECT pa.administrator_id AS "Administrator", pa.primary_doctor_id AS "Primary Doctor ID", pt.doctor_id as "Doctor Involved in Treatment ID"
FROM Patient_Admitted pa
LEFT JOIN PerformTreatment pt
ON pa.admit_id = pt.admit_id
LEFT JOIN Administer_Treatment at 
ON pa.admit_id = at.admit_id
WHERE pa.admit_id NOT IN (SELECT admit_id FROM Patient_Discharged)
