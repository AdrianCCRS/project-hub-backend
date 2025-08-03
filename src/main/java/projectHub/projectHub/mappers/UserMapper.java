package projectHub.projectHub.mappers;

import projectHub.projectHub.Dto.UserDTO;
import projectHub.projectHub.Entity.User;

public class UserMapper {
    public static UserDTO toDTO(User user) {
        if (user == null) return null;
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setEmail(user.getEmail());
        dto.setProgram(user.getProgram());
        dto.setDescription(user.getDescription());
        dto.setCreatedAt(user.getCreatedAt().toString());
        return dto;
    }
}
