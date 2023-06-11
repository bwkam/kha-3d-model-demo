#version 450

in vec3 aPos;
in vec3 aNormal;
in vec2 aTexCoords;

out vec2 TexCoords;
out vec3 FragPos;
out vec3 Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    FragPos = vec3(model * vec4(aPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;  

    TexCoords = aTexCoords;    
    gl_Position = proj * view * model * vec4(aPos, 1.0);
}