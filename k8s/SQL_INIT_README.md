# 📊 SQL Initialization Script - ProjectHub

## Overview

This directory contains SQL initialization scripts for populating the ProjectHub database with test data for performance testing.

## Files

### `init-db.sql`
Standalone SQL script that can be executed directly against MySQL.

### `mysql-initdb-configmap.yaml`
Kubernetes ConfigMap containing the initialization script. This is automatically mounted to MySQL's `/docker-entrypoint-initdb.d/` directory.

## Test Data Summary

The initialization script creates:

- **150 Users** - Mix of realistic and generated test users
  - 30 named users with detailed profiles (Computer Science, Software Engineering, Information Systems)
  - 120 generated test users
  - All users have password: `password123` (BCrypt hashed)

- **50 User Groups** - Project teams with leaders
  - 20 named groups (Cloud Computing Team, AI Research Group, etc.)
  - 30 generated project teams
  - Each group has a designated leader

- **300 Projects** - Diverse project portfolio
  - 30 detailed projects with realistic descriptions
  - 270 generated projects
  - Status distribution: PENDING, IN_PROGRESS, COMPLETED, CANCELLED
  - All projects assigned to groups

- **~350-400 Group Memberships** - User-to-group associations
  - Leaders automatically added to their groups
  - 3-8 members per group on average

## How It Works

### Automatic Initialization (Kubernetes)

When MySQL starts for the **first time** in Kubernetes:

1. MySQL container starts
2. Detects empty database
3. Executes all `.sql` files in `/docker-entrypoint-initdb.d/`
4. Our `init-db.sql` is mounted there via ConfigMap
5. Database is populated automatically

> **Note:** The script only runs on **first startup** when the database is empty. If you need to re-initialize:
> - Delete the PVC: `kubectl delete pvc mysql-pvc -n projecthub-database`
> - Redeploy MySQL

### Manual Execution

If you want to run the script manually:

```bash
# Copy script to MySQL pod
kubectl cp k8s/init-db.sql <mysql-pod-name>:/tmp/init-db.sql -n projecthub-database

# Execute script
kubectl exec -it <mysql-pod-name> -n projecthub-database -- \
  mysql -u projecthub -pprojecthub123 project_db < /tmp/init-db.sql
```

Or connect directly:

```bash
# Connect to MySQL
kubectl exec -it <mysql-pod-name> -n projecthub-database -- \
  mysql -u projecthub -pprojecthub123 project_db

# Then paste the SQL commands
```

## Test User Credentials

All test users have the same password for easy testing:

| Email | Password | Program |
|-------|----------|---------|
| `adrian.rodriguez@university.edu` | `password123` | Computer Science |
| `maria.garcia@university.edu` | `password123` | Computer Science |
| `user31@university.edu` | `password123` | Computer Science |
| ... | `password123` | ... |

## Performance Testing Scenarios

This data enables various performance tests:

### 1. **User Queries**
- List all users (150 records)
- Filter by program
- Search by name/email
- Pagination testing

### 2. **Group Operations**
- List groups with member counts
- Find groups by leader
- Complex joins (groups → users → projects)

### 3. **Project Queries**
- List all projects (300 records)
- Filter by status
- Search by title/description
- Group projects by team

### 4. **Complex Queries**
- Users with their groups and projects
- Groups with all members and projects
- Project statistics by group
- Multi-table joins and aggregations

## Modifying the Data

### Change Number of Records

Edit the script and modify these sections:

```sql
-- Change user count (line ~70)
WHERE 31 + a.N + b.N * 10 + c.N * 100 <= 150  -- Change 150 to desired count

-- Change group count (line ~150)
WHERE 21 + a.N + b.N * 10 <= 50  -- Change 50 to desired count

-- Change project count (line ~250)
WHERE 31 + a.N + b.N * 10 + c.N * 100 <= 300  -- Change 300 to desired count
```

### Add Custom Data

Add your own INSERT statements before the generated data sections.

## Verification

After deployment, verify the data:

```bash
# Get MySQL pod name
kubectl get pods -n projecthub-database

# Connect and check counts
kubectl exec -it <mysql-pod-name> -n projecthub-database -- \
  mysql -u projecthub -pprojecthub123 project_db -e "
    SELECT 'Users' as Entity, COUNT(*) as Count FROM users
    UNION ALL
    SELECT 'Groups', COUNT(*) FROM user_groups
    UNION ALL
    SELECT 'Projects', COUNT(*) FROM projects
    UNION ALL
    SELECT 'Memberships', COUNT(*) FROM user_group_members;
  "
```

Expected output:
```
+-------------+-------+
| Entity      | Count |
+-------------+-------+
| Users       |   150 |
| Groups      |    50 |
| Projects    |   300 |
| Memberships |   350 |
+-------------+-------+
```

## Troubleshooting

### Script didn't execute

**Symptoms:** Database is empty after deployment

**Solutions:**
1. Check if PVC had existing data (script only runs on empty DB)
2. Check MySQL logs: `kubectl logs <mysql-pod> -n projecthub-database`
3. Verify ConfigMap is mounted: `kubectl describe pod <mysql-pod> -n projecthub-database`

### Duplicate key errors

**Symptoms:** Script fails with duplicate entry errors

**Solution:** The database already has data. Delete PVC and redeploy:
```bash
kubectl delete pvc mysql-pvc -n projecthub-database
kubectl delete pod <mysql-pod> -n projecthub-database
```

### Performance issues

**Symptoms:** Script takes too long to execute

**Solutions:**
1. Reduce number of generated records
2. Add indexes after data load
3. Increase MySQL resources in deployment

## Integration with Application

The application (Spring Boot) will automatically use this data:

- **Authentication:** Login with any test user email + `password123`
- **API Testing:** Use existing user/group/project IDs
- **Frontend:** Display real data immediately

## Next Steps

1. **Deploy:** Run `./scripts/deploy-k8s.sh`
2. **Verify:** Check data counts (see Verification section)
3. **Test:** Use test credentials to login
4. **Performance Test:** Run load tests against populated database

---

**Created:** 2025-11-20  
**Purpose:** Performance testing and development  
**Maintainer:** ProjectHub Team
