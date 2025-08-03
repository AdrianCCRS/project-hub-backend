package projectHub.projectHub.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import projectHub.projectHub.Dto.UserGroupDTO;
import projectHub.projectHub.Dto.UserGroupRequestDTO;
import projectHub.projectHub.Entity.User;
import projectHub.projectHub.Entity.UserGroup;
import projectHub.projectHub.Service.UserGroupService;
import projectHub.projectHub.Service.UserService;
import projectHub.projectHub.mappers.UserGroupMapper;

import java.util.List;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class UserGroupController {

    private final UserGroupService groupService;
    private final UserService userService;


    @PostMapping
    public ResponseEntity<?> createGroup(@RequestBody UserGroupRequestDTO requestDTO) {
        requestDTO.setId(null);
        User leader = userService.findById(requestDTO.getLeaderId()).orElse(null);
        if (leader == null) {
            return ResponseEntity.badRequest().body("Leader not found");
        }
        UserGroup group = new UserGroup();
        group.setName(requestDTO.getName());
        group.setLeader(leader);
        group.setId(null);
        UserGroup saved = groupService.save(group);
        UserGroupDTO response = UserGroupMapper.toDTO(saved);
        return ResponseEntity.ok(response);
    }
    @PutMapping
    public ResponseEntity<?> updateGroup(@RequestBody UserGroupRequestDTO group) {
        if (group.getId() == null) {
            return ResponseEntity.badRequest().body("Group id null");
        }
        User leader = userService.findById(group.getLeaderId()).orElse(null);
        if (leader == null) {
            return ResponseEntity.badRequest().body("Leader not found");
        }
        UserGroup existingGroup = groupService.findById(group.getId()).orElse(null);
        if (existingGroup == null) {
            return ResponseEntity.badRequest().body("Group not found");
        }
        existingGroup.setName(group.getName());
        existingGroup.setLeader(leader);
        UserGroup saved = groupService.save(existingGroup);
        UserGroupDTO response = UserGroupMapper.toDTO(saved);

        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<UserGroupDTO>> getAllGroups() {
        /* NO SE PUEDE ELIMINAR A UN LIDER DE GRUPO*/
        return ResponseEntity.ok(groupService.findAll().stream().map(UserGroupMapper::toDTO).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserGroupDTO> getGroupById(@PathVariable Integer id) {
        UserGroupDTO groupDTO = UserGroupMapper.toDTO(groupService.findById(id).orElse(null));
        return ResponseEntity.ok(groupDTO);
    }

    @GetMapping("/editable/{leaderId}")
    public ResponseEntity<List<UserGroupDTO>> getEditableGroups(@PathVariable Integer leaderId) {
        List<UserGroupDTO> allGroups = groupService.findAll()
                .stream()
                .map(UserGroupMapper::toDTO)
                .filter(group -> group.getLeaderId().equals(leaderId))
                .toList();
        return ResponseEntity.ok(allGroups);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteGroup(@PathVariable Integer id) {
        groupService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}