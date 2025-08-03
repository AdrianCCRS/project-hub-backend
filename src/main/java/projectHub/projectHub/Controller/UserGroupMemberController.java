package projectHub.projectHub.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import projectHub.projectHub.Dto.UserDTO;
import projectHub.projectHub.Dto.UserGroupDTO;
import projectHub.projectHub.Dto.UserGroupMemberDTO;
import projectHub.projectHub.Dto.UserGroupMemberResponseDTO;
import projectHub.projectHub.Entity.User;
import projectHub.projectHub.Entity.UserGroup;
import projectHub.projectHub.Entity.UserGroupMember;
import projectHub.projectHub.Entity.UserGroupMemberId;
import projectHub.projectHub.Service.UserGroupMemberService;
import projectHub.projectHub.Service.UserGroupService;
import projectHub.projectHub.Service.UserService;
import projectHub.projectHub.mappers.UserGroupMemberMapper;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/group-members")
@RequiredArgsConstructor
public class UserGroupMemberController {

    private final UserGroupMemberService memberService;
    private final UserService userService;
    private final UserGroupService userGroupService;

    // Añadir un usuario a un grupo
    @PostMapping
    public ResponseEntity<?> addMember(@RequestBody UserGroupMemberDTO member) {
        System.out.println(member);
        UserGroupMember userGroupMember = new UserGroupMember();
        System.out.println(member.getUserId() +"   " + member.getGroupId());
        User user = userService.findById(member.getUserId()).orElse(null);
        System.out.println(user);
        UserGroup group = userGroupService.findById(member.getGroupId()).orElse(null);
        System.out.println(group);
        if (group == null || user == null) {
            return ResponseEntity.badRequest().body("User or group not found");
        }
        userGroupMember.setUser(user);
        userGroupMember.setGroup(group);
        UserGroupMember savedUserGroupMember = memberService.save(userGroupMember);

        UserGroupMemberResponseDTO userGroupMemberResponseDTO = UserGroupMemberMapper.toDTO(savedUserGroupMember);
        return ResponseEntity.ok(userGroupMemberResponseDTO);
    }
    @PostMapping("/addMultiple")
    public ResponseEntity<?> addMembers(@RequestBody List<UserGroupMemberDTO> members) {
        List<UserGroupMemberResponseDTO> responses = new ArrayList<>();

        for (UserGroupMemberDTO member : members) {
            User user = userService.findById(member.getUserId()).orElse(null);
            UserGroup group = userGroupService.findById(member.getGroupId()).orElse(null);

            if (user == null || group == null) {
                return ResponseEntity.badRequest().body("Invalid user or group ID: " + member);
            }

            if (memberService.findByGroupId(member.getGroupId()).stream().anyMatch(u -> u.getUser().equals(user))) {
                continue;
            }
            UserGroupMember userGroupMember = new UserGroupMember();
            userGroupMember.setUser(user);
            userGroupMember.setGroup(group);
            UserGroupMember saved = memberService.save(userGroupMember);
            responses.add(UserGroupMemberMapper.toDTO(saved));
        }

        return ResponseEntity.ok(responses);
    }

    // Obtener todos los miembros de un grupo
    @GetMapping("/group/{groupId}")
    public ResponseEntity<List<UserDTO>> getMembersByGroup(@PathVariable Integer groupId) {
        return ResponseEntity.ok(memberService.findByGroupId(groupId).stream().map(UserGroupMemberMapper::toUserDTO).toList());
    }

    // Obtener todos los grupos a los que pertenece un usuario
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<UserGroupDTO>> getGroupsByUser(@PathVariable Integer userId) {
        return ResponseEntity.ok(memberService.findByUserId(userId).stream().map(UserGroupMemberMapper::toUserGroupDTO).toList());
    }

    // Eliminar un usuario de un grupo
    @DeleteMapping("/user/{userId}/group/{groupId}")
    public ResponseEntity<Void> removeMember(@PathVariable Integer userId, @PathVariable Integer groupId) {
        User user = new User();
        user.setId(userId);

        UserGroup group = new UserGroup();
        group.setId(groupId);

        UserGroupMember member = new UserGroupMember();
        member.setUser(user);
        member.setGroup(group);

        memberService.delete(member);
        return ResponseEntity.noContent().build();
    }
    //Eliminar un array de usuarios
    @DeleteMapping("/deleteMultiple/group/{groupId}")
    public ResponseEntity<Void> removeMultipleMembers(@PathVariable Integer groupId, @RequestBody List<UserGroupMemberDTO> members) {
        for (UserGroupMemberDTO member : members) {
            User user = new User();
            user.setId(member.getUserId());
            UserGroup group = new UserGroup();
            group.setId(groupId);
            UserGroupMember member1 = new UserGroupMember();
            member1.setUser(user);
            member1.setGroup(group);
            memberService.delete(member1);
        }
        return ResponseEntity.noContent().build();
    }
}