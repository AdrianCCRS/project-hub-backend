package projectHub.projectHub.mappers;

import org.apache.catalina.Group;
import projectHub.projectHub.Dto.UserDTO;
import projectHub.projectHub.Dto.UserGroupDTO;
import projectHub.projectHub.Dto.UserGroupMemberResponseDTO;
import projectHub.projectHub.Entity.User;
import projectHub.projectHub.Entity.UserGroup;
import projectHub.projectHub.Entity.UserGroupMember;

import javax.swing.*;

public class UserGroupMemberMapper {
    public static UserGroupMemberResponseDTO toDTO (UserGroupMember member) {
        User user = member.getUser();
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setFirstName(user.getFirstName());
        userDTO.setLastName(user.getLastName());
        userDTO.setEmail(user.getEmail());
        userDTO.setProgram(user.getProgram());
        userDTO.setDescription(user.getDescription());


        return new UserGroupMemberResponseDTO(userDTO);
    }
    public static UserGroupDTO toUserGroupDTO (UserGroupMember member) {
        UserGroup group = member.getGroup();
        UserGroupDTO userGroupDTO = new UserGroupDTO();
        userGroupDTO.setId(group.getId());
        userGroupDTO.setName(group.getName());
        userGroupDTO.setCreatedAt(group.getCreatedAt());
        userGroupDTO.setUpdatedAt(group.getUpdatedAt());
        if (group.getLeader() != null) {
            userGroupDTO.setLeaderId(group.getLeader().getId());
        }
        return userGroupDTO;
    }

    public static UserDTO toUserDTO (UserGroupMember member) {
        User user = member.getUser();
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setFirstName(user.getFirstName());
        userDTO.setLastName(user.getLastName());
        userDTO.setEmail(user.getEmail());
        userDTO.setProgram(user.getProgram());
        userDTO.setDescription(user.getDescription());
        return userDTO;
    }
}
