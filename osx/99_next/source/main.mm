/*
 main.mm
 article-01-skeleton

 Copyright 2012 Thomas Dalling - http://tomdalling.com/

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


// third-party libraries
#import <Foundation/Foundation.h>
#include <GL/glew.h>
#include <GL/glfw.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

// standard C++ libraries
#include <cassert>
#include <iostream>
#include <stdexcept>
#include <cmath>

// tdogl classes
#include "tdogl/Program.h"
#include "tdogl/Texture.h"
#include "tdogl/Camera.h"

// constants
const glm::vec2 SCREEN_SIZE(800, 600);

// globals
tdogl::Camera gCamera;
tdogl::Texture* gTexture = NULL;
tdogl::Program* gProgram = NULL;
GLuint gVAO = 0;
GLuint gVBO = 0;


// returns the full path to the file `fileName` in the resources directory of the app bundle
static std::string ResourcePath(std::string fileName) {
    NSString* fname = [NSString stringWithCString:fileName.c_str() encoding:NSUTF8StringEncoding];
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fname];
    return std::string([path cStringUsingEncoding:NSUTF8StringEncoding]);
}


// loads the vertex shader and fragment shader, and links them to make the global gProgram
static void LoadShaders() {
    std::vector<tdogl::Shader> shaders;
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("vertex-shader.txt"), GL_VERTEX_SHADER));
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("fragment-shader.txt"), GL_FRAGMENT_SHADER));
    gProgram = new tdogl::Program(shaders);
}


// loads a triangle into the VAO and VBO globals: gVAO and gVBO
static void LoadTriangle() {
    // make and bind the VAO
    glGenVertexArrays(1, &gVAO);
    glBindVertexArray(gVAO);
    
    // make and bind the VBO
    glGenBuffers(1, &gVBO);
    glBindBuffer(GL_ARRAY_BUFFER, gVBO);
    
    // Put the three triangle points into the VBO
    GLfloat vertexData[] = {
        //  X     Y     Z      R    G    B    A       U     V
        // bottom
         0.0f, 0.0f,-0.4f,   1.0, 1.0, 1.0, 1.0,   0.5f, 1.0f,
         0.2f, 0.0f, 0.4f,   1.0, 1.0, 1.0, 1.0,   1.0f, 0.0f,
        -0.2f, 0.0f, 0.4f,   1.0, 1.0, 1.0, 1.0,   0.0f, 0.0f,

        // back
         0.0f, 0.4f, 0.4f,   0.4, 0.1, 0.1, 1.0,   0.5f, 1.0f,
        -0.2f, 0.0f, 0.4f,   0.4, 0.1, 0.1, 1.0,   0.0f, 0.0f,
         0.2f, 0.0f, 0.4f,   0.4, 0.1, 0.1, 1.0,   1.0f, 0.0f,

        // left
         0.0f, 0.0f,-0.4f,   1.0, 1.0, 1.0, 1.0,   0.5f, 1.0f,
        -0.2f, 0.0f, 0.4f,   1.0, 1.0, 1.0, 1.0,   0.0f, 0.0f,
         0.0f, 0.4f, 0.4f,   1.0, 1.0, 1.0, 1.0,   1.0f, 0.0f,

        // right
         0.0f, 0.0f,-0.4f,   1.0, 1.0, 1.0, 1.0,   0.5f, 1.0f,
         0.0f, 0.4f, 0.4f,   1.0, 1.0, 1.0, 1.0,   1.0f, 0.0f,
         0.2f, 0.0f, 0.4f,   1.0, 1.0, 1.0, 1.0,   0.0f, 0.0f
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    // connect the xyz to the "vert" attribute of the vertex shader
    glEnableVertexAttribArray(gProgram->attrib("vert"));
    glVertexAttribPointer(gProgram->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 9*sizeof(GLfloat), NULL);
    
    // connect the rgba to the "vertColor" attribute of the vertex shader
    glEnableVertexAttribArray(gProgram->attrib("vertColor"));
    glVertexAttribPointer(gProgram->attrib("vertColor"), 3, GL_FLOAT, GL_TRUE,  9*sizeof(GLfloat), (const GLvoid*)(3 * sizeof(GLfloat)));
    
    // connect the uv coords to the "vertTexCoord" attribute of the vertex shader
    glEnableVertexAttribArray(gProgram->attrib("vertTexCoord"));
    glVertexAttribPointer(gProgram->attrib("vertTexCoord"), 2, GL_FLOAT, GL_TRUE,  9*sizeof(GLfloat), (const GLvoid*)(7 * sizeof(GLfloat)));

    // unbind the VAO
    glBindVertexArray(0);
}


// loads the file "hazard.png" into gTexture
static void LoadTexture() {
    tdogl::Bitmap bmp = tdogl::Bitmap::bitmapFromFile(ResourcePath("hazard.png"));
    bmp.flipVertically();
    gTexture = new tdogl::Texture(bmp);
}


// draws a single frame
static void Render() {
    // clear everything
    glClearColor(0, 0, 0, 1); // black
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // bind the program (the shaders)
    gProgram->use();

    // set the uniform for the camera
    gProgram->setUniform("camera", gCamera.matrix());
        
    // bind the texture and set the "tex" uniform in the fragment shader
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gTexture->object());
    gProgram->setUniform("tex", 0); //set to 0 because the texture is bound to GL_TEXTURE0

    // bind the VAO (the triangle)
    glBindVertexArray(gVAO);
    
    // draw the VAO
    glDrawArrays(GL_TRIANGLES, 0, 12);
    
    // unbind the VAO, the program and the texture
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    gProgram->stopUsing();
    
    // swap the display buffers (displays what was just drawn)
    glfwSwapBuffers();
}


// update the scene based on the time elapsed since last update
void Update(float secondsElapsed) {
    //move position of camera based on WASD keys
    if(glfwGetKey('S')){
        gCamera.offsetPosition(secondsElapsed * -gCamera.forward());
    } else if(glfwGetKey('W')){
        gCamera.offsetPosition(secondsElapsed * gCamera.forward());
    }
    if(glfwGetKey('A')){
        gCamera.offsetPosition(secondsElapsed * -gCamera.right());
    } else if(glfwGetKey('D')){
        gCamera.offsetPosition(secondsElapsed * gCamera.right());
    }
    if(glfwGetKey('Z')){
        gCamera.offsetPosition(secondsElapsed * -glm::vec3(0,1,0));
    } else if(glfwGetKey('X')){
        gCamera.offsetPosition(secondsElapsed * glm::vec3(0,1,0));
    }

    //rotate camera based on mouse movement
    const float mouseSensitivity = 0.1;
    int mouseX, mouseY;
    glfwGetMousePos(&mouseX, &mouseY);
    gCamera.offsetOrientation(mouseSensitivity * mouseY, mouseSensitivity * mouseX);
    glfwSetMousePos(0, 0); //reset the mouse, so it doesn't go out of the window

    //increase or decrease field of view based on mouse wheel
    std::cerr << (float)glfwGetMouseWheel() << std::endl;
    const float zoomSensitivity = -0.2;
    float fieldOfView = gCamera.fieldOfView() + zoomSensitivity * (float)glfwGetMouseWheel();
    if(fieldOfView < 5.0f) fieldOfView = 5.0f;
    if(fieldOfView > 130.0f) fieldOfView = 130.0f;
    gCamera.setFieldOfView(fieldOfView);
    glfwSetMouseWheel(0);
}

// the program starts here
int main(int argc, char *argv[]) {
    // initialise GLFW
    if(!glfwInit())
        throw std::runtime_error("glfwInit failed");
    
    // open a window with GLFW
    glfwOpenWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwOpenWindowHint(GLFW_OPENGL_VERSION_MAJOR, 3);
    glfwOpenWindowHint(GLFW_OPENGL_VERSION_MINOR, 2);
    glfwOpenWindowHint(GLFW_WINDOW_NO_RESIZE, GL_TRUE);
    if(!glfwOpenWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, 8, 8, 8, 8, 16, 0, GLFW_WINDOW))
        throw std::runtime_error("glfwOpenWindow failed. Can your hardware handle OpenGL 3.2?");

    // GLFW settings
    glfwDisable(GLFW_MOUSE_CURSOR);
    glfwSetMousePos(0, 0);
    glfwSetMouseWheel(0);

    // initialise GLEW
    glewExperimental = GL_TRUE; //stops glew crashing on OSX :-/
    if(glewInit() != GLEW_OK)
        throw std::runtime_error("glewInit failed");
    
    // GLEW throws some errors, so discard all the errors so far
    while(glGetError() != GL_NO_ERROR) {}

    // OpenGL settings
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
    gCamera.setPosition(glm::vec3(0, 0, 2));
    gCamera.setViewportAspectRatio(SCREEN_SIZE.x/SCREEN_SIZE.y);

    // load vertex and fragment shaders into opengl
    LoadShaders();
    
    // load the texture
    LoadTexture();

    // create buffer and fill it with the points of the triangle
    LoadTriangle();

    // run while the window is open
    double lastTime = glfwGetTime();
    while(glfwGetWindowParam(GLFW_OPENED)){
        // update the scene based on the time elapsed since last update
        double thisTime = glfwGetTime();
        Update(thisTime - lastTime);
        lastTime = thisTime;
        
        // draw one frame
        Render();

        // check for errors
        GLenum error = glGetError();
        if(error != GL_NO_ERROR)
            std::cerr << "OpenGL Error " << error << ": " << (const char*)gluErrorString(error) << std::endl;

        if(glfwGetKey(GLFW_KEY_ESC)){
            glfwCloseWindow();
        }
    }
    
    // clean up and exit
    glfwTerminate();
    return EXIT_SUCCESS;
}
