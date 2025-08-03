package projectHub.projectHub.Dto;

import lombok.Data;

@Data
public class UserDTO {
    private Integer id;
    private String firstName;
    private String lastName;
    private String email;
    private String description;
    private String program;
    private String createdAt;
}
