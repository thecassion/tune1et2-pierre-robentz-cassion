col operation format a15
col options format a15
col object_name format a12
col id format 99
col pere format 99
col position format 99
col orig_pos format 99


SELECT OPERATION, OPTIONS, OBJECT_NAME, ID, parent_id "PERE", position, OBJECT_INSTANCE "ORIG_POS"
	FROM PLAN_TABLE
	WHERE STATEMENT_ID='USERNAME'
	CONNECT BY PRIOR ID=PARENT_ID
		AND STATEMENT_ID='USERNAME'
		START WITH ID=0
		AND STATEMENT_ID='USERNAME'
	ORDER BY ID;
