
var Clock = function() {
  this.startTime = new Date();
};

Clock.prototype.tick = function () {
  var currentTime = new Date() - this.startTime;

  if (this.ontick) {
    this.ontick(currentTime/1000);
  }

  requestAnimationFrame(this.tick.bind(this));
};


Clock.prototype.start = function () {
  this.tick();
};

export default Clock;
