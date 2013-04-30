-- Find Orbitrap terms
SELECT *
FROM V_Term
WHERE term_name LIKE '%orbitrap%'
ORDER BY namespace, term_name

-- View parents of orbitrap terms
SELECT *
FROM V_Term_Lineage
WHERE term_name LIKE '%orbitrap%'
ORDER BY namespace, term_name

-- Find all children of "mass analyzer type"
SELECT *
FROM V_Term_Lineage
WHERE parent_term_name like 'mass analyzer type'
ORDER BY namespace, term_name

-- Find all children of "instrument"
SELECT *
FROM V_Term_Lineage
WHERE (parent_term_name = 'instrument') and Namespace <> 'EFO'
ORDER BY namespace, term_name

-- View all MS entries and their hierarchy
SELECT *
FROM V_Term_Hierarchy_PSI_MS
ORDER BY Level, Parent_Name, term_name

-- View all MS leaf nodes, with hierarchy
SELECT *
FROM V_Term_Hierarchy_PSI_MS
WHERE is_leaf = 1
ORDER BY Level, Parent_Name, term_name


-- View all PSI-MS entries and their hierarchy
SELECT *
FROM V_Term_Hierarchy_PSI_MS
WHERE is_leaf = 1
ORDER BY Level, Parent_Name, term_name

-- View all PSI_Mod names (only actual mods, not categories)
SELECT *
FROM V_Term_Hierarchy_PSI_Mod
WHERE is_leaf = 1
ORDER BY Level, Parent_Name, term_name
