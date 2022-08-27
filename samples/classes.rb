class DevonshireCream {
  init() {
    this.carrier = "bread";
  }
  serveOn() {
    return this.carrier;
  }
}

var cream = DevonshireCream();
print cream.serveOn();
cream.carrier = "Scones";
print cream.serveOn();

