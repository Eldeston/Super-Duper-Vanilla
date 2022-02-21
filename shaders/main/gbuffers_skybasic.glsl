// Completely disable this program

#ifdef VERTEX
    void main(){
        gl_Position = vec4(0);
    }
#endif

#ifdef FRAGMENT
    void main(){
        discard;
    }
#endif