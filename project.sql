--Q0: the name of the database on the class server in which I can find your schema
--vurya22_db

-----------------------

-- Q1: a list of CREATE TABLE statements implementing your schema
drop table if exists disabilities_diseases cascade;
drop table if exists service_animals cascade;
drop table if exists treatments cascade;
drop table if exists hospitals;
drop table if exists patients;

-- create table patients
CREATE TABLE patients (
   name VARCHAR(150),
   ssn VARCHAR(11),
   age INT,
   ethnicity VARCHAR(30),
   gender VARCHAR(15),
   mental_health INT,
   physical_health INT,
   PRIMARY KEY (ssn, name)
);

-- create table hospitals
CREATE TABLE hospitals (
   hospital_id VARCHAR(7) PRIMARY KEY,
   name VARCHAR(150),
   address VARCHAR(250),
   city VARCHAR(100),
   state CHAR(2),
   zip_code VARCHAR(7)
);

-- create table treatments
CREATE TABLE treatments (
   treatment_type VARCHAR(100),
   patient_ssn VARCHAR(11),
   patient_name VARCHAR(150),
   hospital_id VARCHAR(7),
   date_started DATE,
   date_ended DATE,
   scale_of_improvement INT,
   PRIMARY KEY (treatment_type, patient_ssn, patient_name),
   FOREIGN KEY (patient_ssn, patient_name) REFERENCES patients(ssn, name),
   FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
       ON UPDATE CASCADE
       ON DELETE CASCADE
);

-- create table disabilities_diseases
CREATE TABLE disabilities_diseases (
   name VARCHAR(150),
   patient_ssn VARCHAR(11),
   patient_name VARCHAR(150),
   type VARCHAR(100),
   treatment VARCHAR(100),
   is_hereditary BOOLEAN,
   PRIMARY KEY (name, patient_name, patient_ssn),
   FOREIGN KEY (patient_ssn, patient_name) REFERENCES patients(ssn, name)
       ON UPDATE CASCADE
       ON DELETE CASCADE
);

-- create table service_animals
CREATE TABLE service_animals (
   pet_id VARCHAR(7) PRIMARY KEY,
   pet_name VARCHAR(150),
   species VARCHAR(100),
   breed VARCHAR(150),
   age INT,
   trained_for_service BOOLEAN,
   owner_ssn VARCHAR(11),
   owner_name VARCHAR(150),
   FOREIGN KEY (owner_ssn, owner_name) REFERENCES patients(ssn, name)
       ON UPDATE CASCADE
       ON DELETE CASCADE
);


-------------------------------

--Q2: a list of 10 SQL statements using your schema, along with the English question it implements.

-- Q1 - What treatment seems to have the best outcome in female patients?
SELECT
    t.treatment_type,
    t.scale_of_improvement,
    p.gender
FROM
    treatments t
JOIN
    patients p ON t.patient_ssn = p.ssn AND t.patient_name = p.name
WHERE
    p.gender = 'Female'
ORDER BY
    t.scale_of_improvement DESC
LIMIT 1;

-- Q2 - What disease or disability displays the least overall improvement across patients? 
SELECT
    dd.type AS disease_disability,
    AVG(t.scale_of_improvement) AS average_improvement
FROM
    disabilities_diseases dd
JOIN
    treatments t ON dd.patient_ssn = t.patient_ssn AND dd.patient_name = t.patient_name
GROUP BY
    dd.type
ORDER BY
    average_improvement ASC
LIMIT 1;


-- Q3: Are there specific breeds of service animals that demonstrate a higher effectiveness in alleviating certain medical conditions in their owners? (Patient, Health Practitioner, Researchers, Service Animal Orgs)
SELECT 
    P.name, 
    P.mental_health, 
    P.physical_health, 
    COALESCE(D.name, 'No disabilities/diseases') AS disability,
    COALESCE(S.breed, 'No service pet') AS breed
FROM patients AS P
LEFT JOIN disabilities_diseases AS D 
    ON P.ssn = D.patient_ssn 
	AND P.name = D.patient_name
LEFT JOIN service_animals AS S 
    ON P.ssn = S.owner_ssn 
	AND P.name = S.owner_name
ORDER BY 
    P.mental_health DESC, 
    P.physical_health DESC, 
    S.breed ASC;


-- Q4: medical conditions in their owners?
SELECT
   p.name,
   p.mental_health AS mental_health,
   p.physical_health AS phys_health,
   d.name AS medical_condition,
   s.breed
FROM
   service_animals s
JOIN
   patients p ON s.owner_ssn = p.ssn AND s.owner_name = p.name
JOIN
   disabilities_diseases d ON p.ssn = d.patient_ssn AND d.patient_name = p.name
ORDER BY
   p.mental_health DESC,
   p.physical_health DESC;

-- Q5: Can we determine which hospitals treat certain disabilities/diseases the most?

SELECT
   h.name as hospital_name,
   d.name as medical_condition,
   COUNT(*) as num_treatments
FROM
   hospitals h
JOIN
   treatments t ON t.hospital_id = h.hospital_id
JOIN
   patients p ON p.ssn = t.patient_ssn AND p.name = t.patient_name
JOIN
   (
       SELECT
           patient_ssn,
           patient_name,
           name
       FROM
           disabilities_diseases
   ) d ON d.patient_ssn = p.ssn AND d.patient_name = p.name
GROUP BY
   h.name,
   d.name
ORDER BY
   num_treatments DESC;

-- Q6: what diseases/disabilities seem to show the least improvement in owners with service animals?
SELECT
    dd.type AS disease_disability,
    AVG(t.scale_of_improvement) AS average_improvement
FROM
    disabilities_diseases dd
JOIN
    treatments t ON dd.patient_ssn = t.patient_ssn AND dd.patient_name = t.patient_name
JOIN
    patients p ON dd.patient_ssn = p.ssn AND dd.patient_name = p.name
JOIN
    service_animals sa ON p.ssn = sa.owner_ssn AND p.name = sa.owner_name
GROUP BY
    dd.type
ORDER BY
    average_improvement ASC;

-- Q7: Which hospitals have the most number of patients with service animals?
SELECT
   h.name,
   COUNT(DISTINCT p.ssn) as num_patients,
   COUNT(s.pet_id) as num_animals
FROM
   patients p
LEFT JOIN
   service_animals s ON p.ssn = s.owner_ssn AND p.name = s.owner_name
LEFT JOIN
   treatments t ON p.ssn = t.patient_ssn
LEFT JOIN
   hospitals h ON t.hospital_id = h.hospital_id
GROUP BY
   h.name
ORDER BY
   num_animals DESC
LIMIT 3;

-- Q8: Which diseases are associated with the shortest treatment time?
WITH DiseaseTreatments AS (
    SELECT d.name AS medical_condition, (MIN(t.date_ended) - MIN(t.date_started)) AS num_days
    FROM disabilities_diseases d
    JOIN patients p ON p.ssn = d.patient_ssn AND p.name = d.patient_name
    JOIN treatments t ON t.patient_ssn = p.ssn
    GROUP BY  d.name
)
SELECT
    medical_condition,
    num_days
FROM DiseaseTreatments
ORDER BY num_days;

-- Q9: Is there a trend in the treatment of hereditary diseases? (Health Practitioner)
SELECT
    d.name AS disease_name,
    d.type AS disease_type,
    d.is_hereditary,
    t.treatment_type,
    t.date_started,
    t.date_ended,
    t.scale_of_improvement,
    h.name AS hospital_name
FROM disabilities_diseases d
JOIN treatments t ON d.patient_ssn = t.patient_ssn AND d.patient_name = t.patient_name
JOIN hospitals h ON t.hospital_id = h.hospital_id
WHERE d.is_hereditary = TRUE
ORDER BY d.name, t.date_started;


-- Q10: What treatments have displayed significant improvement in the least amount of time depending on the disease? (Patient, Health Practitioner)
SELECT
    d.patient_name,
    d.type AS disease,
    t.treatment_type,
    t.date_started,
    t.date_ended,
    t.scale_of_improvement,
    (t.date_ended - t.date_started) AS days_of_treatment
FROM disabilities_diseases d
JOIN treatments t ON d.patient_ssn = t.patient_ssn AND d.patient_name = t.patient_name
WHERE t.date_ended IS NOT NULL
ORDER BY days_of_treatment ASC, scale_of_improvement DESC;


-----------------------------

-- Q3: a list of 3-5 demo queries that return (minimal) sensible results. Please specify the team member responsible for each. These can be a subset of the 10 queries implemented for Q2, in which case it's okay to list them twice.

-- Q4: Are there specific breeds of service animals that demonstrate a higher effectiveness in alleviating certain medical conditions in their owners? (Patient, Health Practitioner, Researchers, Service Animal Orgs)

--------------------

-- Q4: reflection on what you learned and challenges