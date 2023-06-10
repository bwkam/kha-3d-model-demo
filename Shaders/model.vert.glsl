#version 450

in vec3 aPos;
in vec3 aNormal;
in vec2 aTexCoords;

out vec2 TexCoords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    TexCoords = aTexCoords;    
    gl_Position = proj * view * model * vec4(aPos, 1.0);
}