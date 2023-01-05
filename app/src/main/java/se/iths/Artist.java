package se.iths;

public class Artist {

    private final long id;
    private String name;

    public Artist(long id, String name){
        this.id = id;
        this.name = name;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String toString(){
        return String.format("%d %s", id, name);
    }

}
