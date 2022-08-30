// Completely disable this program (I won't be using this anytime soon)
/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = vec4(-10);
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    void main(){
        discard;
    }
#endif